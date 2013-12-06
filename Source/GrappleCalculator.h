//
//  GrappleCalculator.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-07.
//
//

@protocol GrappleCalculator <NSObject>

+ (id) sharedInstance;

- (void) calculateHorizontalGrappleWithPlane: (UInt8  *) plane
                                  planeWidth: (size_t  ) width
                                 planeHeight: (size_t  ) height
                                      startX: (size_t  ) startX
                                      startY: (size_t  ) startY
                                   threshold: (UInt8   ) threshold
                                       outX1: (size_t *) outX1
                                       outX2: (size_t *) outX2;

- (void)   calculateVerticalGrappleWithPlane: (UInt8  *) plane
                                  planeWidth: (size_t  ) width
                                 planeHeight: (size_t  ) height
                                      startX: (size_t  ) startX
                                      startY: (size_t  ) startY
                                   threshold: (UInt8   ) threshold
                                       outY1: (size_t *) outY1
                                       outY2: (size_t *) outY2;

- (void) calculateExpansionWithPlane: (UInt8 *) plane
                          planeWidth: (size_t ) width
                         planeHeight: (size_t ) height
                              inRect: (CGRect ) inRect
                                edge: (ObjectEdge) edge
                             outRect: (CGRect *) outRect;

- (void) calculateShrinkageWithPlane: (UInt8 *) plane
                          planeWidth: (size_t ) width
                         planeHeight: (size_t ) height
                              inRect: (CGRect ) inRect
                                edge: (ObjectEdge) edge
                             outRect: (CGRect *) outRect;


@end
