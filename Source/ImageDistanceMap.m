//
//  ImageMapper.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-11.
//
//

#import "ImageDistanceMap.h"

#import <Accelerate/Accelerate.h>
#import "WinchFastMath.h"

NSString * const ImageDistanceMapReadyNotificationName = @"ImageDistanceMapReady";


#define DUMP_MAPS  0

@implementation ImageDistanceMap {
    CGImageRef  _image;
    UInt8      *_horizontalPlane;
    UInt8      *_verticalPlane;
    BOOL        _building;
}


- (id) initWithCGImage:(CGImageRef)image
{
    if ((self = [super init])) {
        _image = CGImageRetain(image);
    }
    
    return self;
}


- (void) dealloc
{
    CGImageRelease(_image);

    free(_horizontalPlane);
    free(_verticalPlane);
}


#pragma mark - Private Methods

static __inline__ void sMakeLAB(UInt8 *inRGB, float *outLAB, size_t width, size_t height)
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
            float X = f[i + 0];
            float Y = f[i + 1];
            float Z = f[i + 2];
            
            f[i] = (116.f * Y) - 16.f;
            if (f[i] < 0) f[i] = 0;
            
            f[i+1] = 500.f * (X - Y);
            f[i+2] = 200.f * (Y - Z);
            f[i+3] = 0;
        }
    });
}


- (void) _worker_buildMaps
{
    size_t width  = CGImageGetWidth(_image);
    size_t height = CGImageGetHeight(_image);

    NSInteger bytesPerRow = 4 * width;
    UInt8    *input          = malloc(sizeof(UInt8) * bytesPerRow * (height + 1));
    float    *lab_accelerate = malloc(sizeof(float) * 4 * width * (height + 1));

    UInt8    *hmap_accelerate = malloc(sizeof(UInt8) * 4 * width * (height + 1));
    UInt8    *vmap_accelerate = malloc(sizeof(UInt8) * 4 * width * (height + 1));

    // Draw image into input buffer
    //
    {
        CGContextRef context = CGBitmapContextCreate(input, width, height, 8, bytesPerRow, CGImageGetColorSpace(_image), 0|kCGImageAlphaNoneSkipLast);

        CGContextFillRect(context, CGRectMake(0, 0, width, height));
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), _image);

        CGContextRelease(context);
    }
    memset(&lab_accelerate[4 * width * height], 0, sizeof(float) * width * 4);

    sMakeLAB(input, lab_accelerate, width, height);
    free(input);

    if (SupportsSSE4_1()) {
        CalculateImageDistanceMap_SSE4(lab_accelerate, hmap_accelerate, vmap_accelerate, width, height);
    } else {
        CalculateImageDistanceMap_SSE3(lab_accelerate, hmap_accelerate, vmap_accelerate, width, height);
    }

    free(lab_accelerate);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _building = NO;
        _horizontalPlane = hmap_accelerate;
        _verticalPlane   = vmap_accelerate;

        [[NSNotificationCenter defaultCenter] postNotificationName:ImageDistanceMapReadyNotificationName object:self];
    });
}


- (void) dump
{
    if (!_horizontalPlane || !_verticalPlane) {
        return;
    }

    size_t width  = CGImageGetWidth(_image);
    size_t height = CGImageGetHeight(_image);

    CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
    
    CGContextRef vertical = CGBitmapContextCreate(NULL, width, height, 8, width, gray, 0|kCGImageAlphaNone);
    UInt8 *vBytes = (UInt8 *)CGBitmapContextGetData(vertical);

    CGContextRef horizontal = CGBitmapContextCreate(NULL, width, height, 8, width, gray, 0|kCGImageAlphaNone);
    UInt8 *hBytes = (UInt8 *)CGBitmapContextGetData(horizontal);
    
    for (NSInteger i = 0; i < (width * height); i++) {
        vBytes[i] = _verticalPlane[i];
        hBytes[i] = _horizontalPlane[i];
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


#pragma mark - Accessors

- (void) buildMaps
{
    if (_horizontalPlane || _verticalPlane || _building) return;
    _building = YES;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self _worker_buildMaps];
    });
}


- (size_t) width
{
    return CGImageGetWidth(_image);
}


- (size_t) height
{
    return CGImageGetHeight(_image);
}


- (UInt8 *) horizontalPlane
{
    return _horizontalPlane;
}


- (UInt8 *) verticalPlane
{
    return _verticalPlane;
}


@end
