//
//  GrappleCalculator.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-06.
//
//

#import "GrappleCalculator.h"

#define DUMP_MAPS 0

@implementation GrappleCalculator {
    CGImageRef _image;
    size_t     _width;
    size_t     _height;
    UInt8     *_horizontalMap;
    UInt8     *_verticalMap;
}

- (id) initWithImage:(CGImageRef)image
{
    if ((self = [super init])) {
        _image  = CGImageRetain(image);
        _width  = CGImageGetWidth(_image);
        _height = CGImageGetHeight(_image);
    }

    return self;
}


- (void) dealloc
{
    CGImageRelease(_image);
    free(_horizontalMap);
    free(_verticalMap);
}



- (void) _buildMapsForImage
{
    if (_horizontalMap || _verticalMap) return;

    CFDataRef data = NULL;

    size_t bytesPerRow = CGImageGetBytesPerRow(_image);

    if (1) {
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Little;

        CGColorSpaceRef space   = CGColorSpaceCreateDeviceRGB();
        CGContextRef    context = space ? CGBitmapContextCreate(NULL, _width, _height, 8, 4 * _width, space, bitmapInfo) : NULL;

        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), _image);

            const void *bytes = CGBitmapContextGetData(context);
            data = CFDataCreate(NULL, bytes, 4 * _width * _height);

            bytesPerRow = CGBitmapContextGetBytesPerRow(context);
        }
        
        CGColorSpaceRelease(space);
        CGContextRelease(context);
    }
    
    UInt8 *buffer = data ? (UInt8 *)CFDataGetBytePtr(data) : NULL;
    
    UInt8 *horizontalDeltas = malloc(sizeof(UInt8) * _width * _height);
    UInt8 *verticalDeltas   = malloc(sizeof(UInt8) * _width * _height);
    
    if (buffer) {
        for (NSInteger y = 0; y < (_height - 1); y++) {
            for (NSInteger x = 0; x < (_width - 1); x++) {
                UInt8 *here  = buffer + (y * bytesPerRow) + (4 * x);
                UInt8 *right = here + 4;
                UInt8 *down  = here + bytesPerRow;
                
                UInt8 r_here,  g_here,  b_here,  a_here;
                UInt8 r_right, g_right, b_right, a_right;
                UInt8 r_down,  g_down,  b_down,  a_down;
                
                a_here  = here[0];
                r_here  = here[1];
                g_here  = here[2];
                b_here  = here[3];

                a_right = right[0];
                r_right = right[1];
                g_right = right[2];
                b_right = right[3];

                a_down  = down[0];
                r_down  = down[1];
                g_down  = down[2];
                b_down  = down[3];

                size_t offset = (y * _width) + x;

                horizontalDeltas[offset] = (abs((int)r_here - (int)r_right) +
                                            abs((int)g_here - (int)g_right) +
                                            abs((int)b_here - (int)b_right) +
                                            abs((int)a_here - (int)a_right)) / 4;
                
                verticalDeltas[offset]  =  (abs((int)r_here - (int)r_down) +
                                            abs((int)g_here - (int)g_down) +
                                            abs((int)b_here - (int)b_down) +
                                            abs((int)a_here - (int)a_down)) / 4;
            }
        }
    }

    _horizontalMap = horizontalDeltas;
    _verticalMap   = verticalDeltas;

#if DUMP_MAPS
    [self _dumpMaps];
#endif

    if (data) {
        CFRelease(data);
    }
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
    [[nsVImage TIFFRepresentation] writeToFile:@"/tmp/vertical.tiff" atomically:YES];

    CGImageRef hImage = CGBitmapContextCreateImage(horizontal);
    NSImage *nsHImage = [[NSImage alloc] initWithCGImage:hImage size:NSZeroSize];
    [[nsHImage TIFFRepresentation] writeToFile:@"/tmp/horizontal.tiff" atomically:YES];
    
}

#endif



- (void) calculateHorizontalGrappleWithStartX: (size_t  ) startX
                                       startY: (size_t  ) startY
                                    threshold: (UInt8   ) threshold
                                        outX1: (size_t *) outX1
                                        outX2: (size_t *) outX2
{
    if (!_horizontalMap) {
        [self _buildMapsForImage];
    }

    size_t x1 = startX - 1;
    size_t x2 = startX;
    
    while (x1 > 0) {
        UInt16 delta = _horizontalMap[(startY * _width) + x1];

        if (delta > threshold) {
            x1++;
            break;
        }

        x1--;
    }
    
    while (x2 < _width) {
        UInt16 delta = _horizontalMap[(startY * _width) + x2];
        if (delta > threshold) break;
        x2++;
    }
    x2++;
    
    *outX1 = x1;
    *outX2 = x2;

}

- (void) calculateVerticalGrappleWithStartX: (size_t  ) startX
                                     startY: (size_t  ) startY
                                  threshold: (UInt8   ) threshold
                                      outY1: (size_t *) outY1
                                      outY2: (size_t *) outY2
{
    if (!_verticalMap) {
        [self _buildMapsForImage];
    }
    
  
    size_t y1 = startY - 1;
    size_t y2 = startY;
    
//    NSLog(@"Looking up %ld,%ld", (long)startX, (long)startY);
    
    while (y1 > 0) {
        UInt16 delta = _verticalMap[(y1 * _width) + startX];

        if (delta > threshold) {
            y1++;
            break;
        }

        y1--;
    }
    
    while (y2 < _height) {
        UInt16 delta = _verticalMap[(y2 * _width) + startX];
        if (delta > threshold) break;
        y2++;
    }
    y2++;
    
    *outY1 = y1;
    *outY2 = y2;
}


@end
