//
//  ImageMapper.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-11.
//
//

#import "ImageMapper.h"
#import "Screenshot.h"

#import <Accelerate/Accelerate.h>
#include <smmintrin.h>


NSString * const ImageMapperDidBuildMapsNotification = @"ImageMapperDidBuildMaps";


static __inline__ __m128 load_floats(const float *value) {
    __m128 xy = _mm_loadl_pi(_mm_setzero_ps(), (const __m64*)value);
    __m128 z = _mm_load_ss(&value[2]);
    return _mm_movelh_ps(xy, z);
}

#define DUMP_MAPS  0

@implementation ImageMapper {
    Screenshot *_screenshot;
    size_t      _width;
    size_t      _height;
    UInt8      *_horizontalMap;
    UInt8      *_verticalMap;
    BOOL        _building;
    BOOL        _ready;
}


- (id) initWithScreenshot:(Screenshot *)screenshot
{
    if ((self = [super init])) {
        _screenshot = screenshot;
        _width  = [_screenshot width];
        _height = [_screenshot height];
    }
    
    return self;
}


- (void) dealloc
{
    free(_horizontalMap);
    free(_verticalMap);
}


#pragma mark - Private Methods

static void sMakeLAB_Accelerate(UInt8 *inRGB, float *outLAB, size_t width, size_t height)
{
     dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // Build LAB buffer
    //
    dispatch_apply(height, queue, ^(size_t y) {
        size_t w4 = width * 4;
        size_t i;
    
        UInt8 *rgb8 = &inRGB[ 4 * width * y];
        float *f    = &outLAB[4 * width * y];
        
        float scalar;
        
        vDSP_vfltu8(rgb8, 1, f, 1, w4);     // f will contain RGB 0.f-255.f

        scalar = 255.f;
        vDSP_vsdiv(f, 1, &scalar, f, 1, w4);  // f will contain RGB 0.f-1.f

        for (i = 0; i < w4; i++) {
            float n = f[i];
            n = (n > 0.04045f ?
                powf((n + 0.055f)/1.055f, 2.4f) :
                n/12.92f
            ) * 100.0f;
            f[i] = n;
        }

        for (i = 0; i < w4; i += 4) {
            const float r = f[i + 0];
            const float g = f[i + 1];
            const float b = f[i + 2];

            f[i + 0] = r*0.4124f + g*0.3576f + b*0.1805f;
            f[i + 1] = r*0.2126f + g*0.7152f + b*0.0722f;
            f[i + 2] = r*0.0193f + g*0.1192f + b*0.9505f;
            f[i + 3] = 0;
        }
        
        scalar = 95.047f;
        vDSP_vsdiv(f+0, 4, &scalar, f+0, 4, width);  // Divide R by 95.047f

        scalar = 100.0f;
        vDSP_vsdiv(f+1, 4, &scalar, f+1, 4, width);  // Divide G by 100.0f

        scalar = 108.883f;
        vDSP_vsdiv(f+2, 4, &scalar, f+2, 4, width);  // Divide B by 108.883f
       
        for (i = 0; i < w4; i ++) {
            float n = f[i];

            n = n > 0.008856f ?
                cbrtf(n) :
                (903.3f * n + 16.0f) / 116.0f;

            f[i] = n;
        }

        for (i = 0; i < w4; i += 4) {
            float x = f[i + 0];
            float y = f[i + 1];
            float z = f[i + 2];
            
            f[i] = (116.f * y) - 16.f;
            if (f[i] < 0) f[i] = 0;
            
            f[i+1] = 500.f * (x - y);
            f[i+2] = 200.f * (y - z);
            f[i+3] = 0;
        }
    });
}


static void sMakeMap_Accelerate(float *inLAB, UInt8 *outHorizontalMap, UInt8 *outVerticalMap, size_t width, size_t height)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_apply(height, queue, ^(size_t y) {
        float *here  = &inLAB[(y * width * 4)];
        float *right = &inLAB[((y * width) + 1)     * 4];
        float *down  = &inLAB[((y * width) + width) * 4];
        
        if (SupportsSSE4_1()) {
            for (size_t x = 0; x < width; x++) {
                __m128 here128  = load_floats(here);
                __m128 right128 = load_floats(right);
                __m128 down128  = load_floats(down);

                __m128 hDelta   = _mm_sub_ps(here128, right128);
                __m128 vDelta   = _mm_sub_ps(here128, down128);
                
                hDelta = _mm_sqrt_ss(_mm_dp_ps(hDelta, hDelta, 0x71));
                vDelta = _mm_sqrt_ss(_mm_dp_ps(vDelta, vDelta, 0x71));

                float hD = _mm_cvtss_f32(hDelta);
                float vD = _mm_cvtss_f32(vDelta);
                
                outHorizontalMap[(y * width) + x] = (UInt8)ceil((hD / 258.693) * 254.0);
                outVerticalMap[  (y * width) + x] = (UInt8)ceil((vD / 258.693) * 254.0);

                here  += 4;
                right += 4;
                down  += 4;
            }

        } else {
            for (size_t x = 0; x < width; x++) {
                __m128 here128  = load_floats(here);
                __m128 right128 = load_floats(right);
                __m128 down128  = load_floats(down);

                __m128 hDelta = _mm_sub_ps(here128, right128);
                __m128 vDelta = _mm_sub_ps(here128, down128);

                hDelta = _mm_mul_ps( hDelta, hDelta);
                hDelta = _mm_hadd_ps(hDelta, hDelta);
                hDelta = _mm_hadd_ps(hDelta, hDelta);
                hDelta = _mm_sqrt_ps(hDelta);

                vDelta = _mm_mul_ps(vDelta, vDelta);
                vDelta = _mm_hadd_ps(vDelta, vDelta);
                vDelta = _mm_hadd_ps(vDelta, vDelta);
                vDelta = _mm_sqrt_ps(vDelta);
                
                float hD = _mm_cvtss_f32(hDelta);
                float vD = _mm_cvtss_f32(vDelta);

                outHorizontalMap[(y * width) + x] = (UInt8)ceil((hD / 258.693) * 254.0);
                outVerticalMap[  (y * width) + x] = (UInt8)ceil((vD / 258.693) * 254.0);

                here  += 4;
                right += 4;
                down  += 4;
            }
        }
    });
}


- (void) _worker_buildMaps
{
    size_t width  = _width;
    size_t height = _height;

    NSInteger bytesPerRow = 4 * width;
    UInt8    *input = malloc(sizeof(UInt8) * bytesPerRow * (height + 1));
    float    *lab_accelerate = malloc(sizeof(float) * 4 * width * (height + 1));

    UInt8    *hmap_accelerate = malloc(sizeof(UInt8) * 4 * width * (height + 1));
    UInt8    *vmap_accelerate = malloc(sizeof(UInt8) * 4 * width * (height + 1));

    // Draw image into input buffer
    //
    {
        CGImageRef image = [_screenshot CGImage];
        CGContextRef context = CGBitmapContextCreate(input, width, height, 8, bytesPerRow, CGImageGetColorSpace(image), kCGImageAlphaNoneSkipLast);

        CGContextFillRect(context, CGRectMake(0, 0, width, height));
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

        CGContextRelease(context);
    }
    memset(&lab_accelerate[4 * width * height], 0, sizeof(float) * width * 4);

    sMakeLAB_Accelerate(input, lab_accelerate, _width, _height);
    sMakeMap_Accelerate(lab_accelerate, hmap_accelerate, vmap_accelerate, _width, _height);

    free(lab_accelerate);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _building = NO;
        _ready = YES;
        _horizontalMap = hmap_accelerate;
        _verticalMap   = vmap_accelerate;

        [[NSNotificationCenter defaultCenter] postNotificationName:ImageMapperDidBuildMapsNotification object:self];

#if DUMP_MAPS
        [self _dumpMaps];
#endif
    });
}


#if DUMP_MAPS

- (void) _dumpMaps
{
    CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
    
    CGContextRef vertical = CGBitmapContextCreate(NULL, _width, _height, 8, _width, gray, kCGImageAlphaNone);
    UInt8 *vBytes = (UInt8 *)CGBitmapContextGetData(vertical);

    CGContextRef horizontal = CGBitmapContextCreate(NULL, _width, _height, 8, _width, gray, kCGImageAlphaNone);
    UInt8 *hBytes = (UInt8 *)CGBitmapContextGetData(horizontal);
    
    for (NSInteger i = 0; i < (_width * _height); i++) {
        vBytes[i] = _verticalMap[i];
        hBytes[i] = _horizontalMap[i];
    }
    
    CGImageRef vImage = CGBitmapContextCreateImage(vertical);
    NSImage *nsVImage = [[NSImage alloc] initWithCGImage:vImage size:NSZeroSize];
    [[nsVImage TIFFRepresentation] writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"vertical.tiff"] atomically:YES];

    CGImageRef hImage = CGBitmapContextCreateImage(horizontal);
    NSImage *nsHImage = [[NSImage alloc] initWithCGImage:hImage size:NSZeroSize];
    [[nsHImage TIFFRepresentation] writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"horizontal.tiff"] atomically:YES];
    
    [[NSWorkspace sharedWorkspace] openFile:NSTemporaryDirectory()];
    
    
    CFRelease(gray);
    CGImageRelease(vImage);
    CGImageRelease(hImage);
    CGContextRelease(vertical);
    CGContextRelease(horizontal);
}

#endif


#pragma mark - Accessors

- (void) buildMaps
{
    if (_ready || _building) return;
    _building = YES;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _worker_buildMaps];
    });
}


- (BOOL) isReady
{
    return _ready;
}


- (UInt8 *) horizontalMap
{
    return _horizontalMap;
}


- (UInt8 *) verticalMap
{
    return _verticalMap;
}


@end
