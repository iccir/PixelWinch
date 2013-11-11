//
//  GrappleCalculator.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-07.
//
//

#import "GrappleCalculatorImpl.h"

@implementation GrappleCalculator

+ (id) sharedInstance
{
    static GrappleCalculator *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[GrappleCalculator alloc] init];
    });
    
    return sSharedInstance;
}


- (void) calculateHorizontalGrappleWithPlane: (UInt8  *) plane
                                  planeWidth: (size_t  ) width
                                 planeHeight: (size_t  ) height
                                      startX: (size_t  ) startX
                                      startY: (size_t  ) startY
                                   threshold: (UInt8   ) threshold
                                       outX1: (size_t *) outX1
                                       outX2: (size_t *) outX2
{
    size_t x1 = startX > 0 ? startX - 1 : 0;
    size_t x2 = startX;
    
    if (startX > 0) {
        while (x1 > 0) {
            UInt16 delta = plane[(startY * width) + x1];

            if (delta > threshold) {
                x1++;
                break;
            }

            x1--;
        }
    }
    
    while (x2 < width) {
        UInt16 delta = plane[(startY * width) + x2];
        if (delta > threshold) break;
        x2++;
    }
    x2++;
    
    *outX1 = x1;
    *outX2 = x2;
}


- (void)   calculateVerticalGrappleWithPlane: (UInt8  *) plane
                                  planeWidth: (size_t  ) width
                                 planeHeight: (size_t  ) height
                                      startX: (size_t  ) startX
                                      startY: (size_t  ) startY
                                   threshold: (UInt8   ) threshold
                                       outY1: (size_t *) outY1
                                       outY2: (size_t *) outY2
{
    if (!plane) return;
  
    size_t y1 = startY > 0 ? startY - 1 : 0;
    size_t y2 = startY;
    
    if (startY > 0) {
        while (y1 > 0) {
            UInt16 delta = plane[(y1 * width) + startX];

            if (delta > threshold) {
                y1++;
                break;
            }

            y1--;
        }
    }
    
    while (y2 < height) {
        UInt16 delta = plane[(y2 * width) + startX];
        if (delta > threshold) break;
        y2++;
    }
    y2++;
    
    *outY1 = y1;
    *outY2 = y2;
}


@end


__attribute__((constructor)) static void sInitializeGrappleCalculator()
{
    [GrappleCalculator class];
}
