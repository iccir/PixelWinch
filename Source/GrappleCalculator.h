//
//  GrappleCalculator.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-06.
//
//

#import <Foundation/Foundation.h>

@interface GrappleCalculator : NSObject

- (id) initWithImage:(CGImageRef)image;

- (void) calculateHorizontalGrappleWithStartX: (size_t  ) startX
                                       startY: (size_t  ) startY
                                    threshold: (UInt8   ) threshold
                                        outX1: (size_t *) outX1
                                        outX2: (size_t *) outX2;

- (void) calculateVerticalGrappleWithStartX: (size_t  ) startX
                                     startY: (size_t  ) startY
                                  threshold: (UInt8   ) threshold
                                      outY1: (size_t *) outY1
                                      outY2: (size_t *) outY2;

@end
