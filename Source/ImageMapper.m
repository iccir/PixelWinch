//
//  ImageMapper.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-11.
//
//

#import "ImageMapper.h"
#import "Screenshot.h"

#import <OpenGL/OpenGL.h>
#import <GLUT/GLUT.h>

#import "kernels.cl.h"

NSString * const ImageMapperDidBuildMapsNotification = @"ImageMapperDidBuildMaps";

#define DUMP_MAPS 1

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

- (void) _worker_buildMaps
{
    dispatch_queue_t dq = gcl_create_dispatch_queue(CL_DEVICE_TYPE_GPU, NULL);
    if (!dq) dq = gcl_create_dispatch_queue(CL_DEVICE_TYPE_CPU, NULL);

    // Step one, make input buffer
    //
    UInt8    *input = NULL;
    NSInteger bytesPerRow;
    BOOL inputNeedsFree = NO;
    BOOL hasAlpha = NO;

    if (!input) {
        input = malloc(sizeof(UInt8) * 4 * _width * (_height + 1));
        inputNeedsFree = YES;
        hasAlpha = YES;
        
        bytesPerRow = 4 * _width;

        CGImageRef image = [_screenshot CGImage];
        CGContextRef context = CGBitmapContextCreate(input, _width, _height, 8, bytesPerRow, CGImageGetColorSpace(image), kCGImageAlphaNoneSkipLast);

        CGContextFillRect(context, CGRectMake(0, 0, _width, _height));
        CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), image);

        CGContextRelease(context);
    }

    size_t width = _width;
    size_t height = _height;
    size_t mapSize = sizeof(UInt8) * width * height;
    void *horizontalMap = malloc(mapSize);
    void *verticalMap   = malloc(mapSize);
    
    dispatch_sync(dq, ^{
        void *inBufferCL   = NULL;
        void *labBufferCL  = gcl_malloc(sizeof(float) * 4 * width * (height + 1), NULL, 0);

        void *horizontalCL = gcl_malloc(mapSize, NULL, 0);
        void *verticalCL   = gcl_malloc(mapSize, NULL, 0);

        if (hasAlpha) {
            cl_ndrange range1 = { 1, {0}, { width * height }, {0} };
            inBufferCL = gcl_malloc(sizeof(UInt8) * 4 * width * (height + 1), (void *)input, CL_MEM_COPY_HOST_PTR);
            convert_rgba_to_lab_kernel(&range1, inBufferCL, labBufferCL);

        } else {
            cl_ndrange range1 = { 1, {0}, { width * height }, {0} };
            inBufferCL = gcl_malloc(sizeof(UInt8) * 3 * width * (height + 1), (void *)input, CL_MEM_COPY_HOST_PTR);
            convert_rgb_to_lab_kernel( &range1, inBufferCL, labBufferCL);
        }

        cl_ndrange range2 = { 1, {0}, { width * height }, {0} };
        make_delta_map_kernel(&range2, labBufferCL,     1, horizontalCL);

        cl_ndrange range3 = { 1, {0}, { width * height }, {0} };
        make_delta_map_kernel(&range3, labBufferCL, width, verticalCL);
        
        gcl_memcpy(horizontalMap, horizontalCL, mapSize);
        gcl_memcpy(verticalMap,   verticalCL,   mapSize);
        
        gcl_free(labBufferCL);
        gcl_free(inBufferCL);
        gcl_free(horizontalCL);
        gcl_free(verticalCL);
    });

    _horizontalMap = horizontalMap;
    _verticalMap   = verticalMap;
    
    if (inputNeedsFree) {
        free(input);
    }

#if DUMP_MAPS
    [self _dumpMaps];
#endif

    dispatch_async(dispatch_get_main_queue(), ^{
        _horizontalMap = horizontalMap;
        _verticalMap   = verticalMap;
        _ready         = YES;
        _building      = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ImageMapperDidBuildMapsNotification object:self];
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
