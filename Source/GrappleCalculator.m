//
//  GrappleCalculator.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-06.
//
//

#import "GrappleCalculator.h"
#import "Canvas.h"
#import "ImageMapper.h"

#define DUMP_MAPS 1

@interface Canvas (Internal)
- (void) _grappleCalculatorReady;
@end


@implementation GrappleCalculator {
    __weak Canvas *_canvas;
    ImageMapper   *_mapper;
    size_t _width;
    size_t _height;
}


- (id) initWithCanvas:(Canvas *)canvas
{
    if ((self = [super init])) {
        _mapper = [[ImageMapper alloc] initWithScreenshot:[canvas screenshot]];
        _canvas = canvas;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleImageMapperDidBuildMaps:) name:ImageMapperDidBuildMapsNotification object:_mapper];
        
        CGSize size = [_canvas size];
        _width  = size.width;
        _height = size.height;
    }

    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) _handleImageMapperDidBuildMaps:(NSNotification *)note
{
    _ready = YES;
    [_canvas _grappleCalculatorReady];
}


- (void) prepare
{
    [_mapper buildMaps];
}


- (void) calculateHorizontalGrappleWithStartX: (size_t  ) startX
                                       startY: (size_t  ) startY
                                    threshold: (UInt8   ) threshold
                                        outX1: (size_t *) outX1
                                        outX2: (size_t *) outX2
{
    UInt8 *horizontalMap = [_mapper horizontalMap];
    if (!horizontalMap) return;

    size_t x1 = startX > 0 ? startX - 1 : 0;
    size_t x2 = startX;
    
    if (startX > 0) {
        while (x1 > 0) {
            UInt16 delta = horizontalMap[(startY * _width) + x1];

            if (delta > threshold) {
                x1++;
                break;
            }

            x1--;
        }
    }
    
    while (x2 < _width) {
        UInt16 delta = horizontalMap[(startY * _width) + x2];
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
    UInt8 *verticalMap = [_mapper verticalMap];
    if (!verticalMap) return;
  
    size_t y1 = startY > 0 ? startY - 1 : 0;
    size_t y2 = startY;
    
    if (startY > 0) {
        while (y1 > 0) {
            UInt16 delta = verticalMap[(y1 * _width) + startX];

            if (delta > threshold) {
                y1++;
                break;
            }

            y1--;
        }
    }
    
    while (y2 < _height) {
        UInt16 delta = verticalMap[(y2 * _width) + startX];
        if (delta > threshold) break;
        y2++;
    }
    y2++;
    
    *outY1 = y1;
    *outY2 = y2;
}


@end
