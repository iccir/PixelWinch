//
//  Guide.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Guide : CanvasObject

+ (instancetype) guideWithOffset:(CGFloat)offset vertical:(BOOL)isVertical;

@property (nonatomic, readonly, getter=isVertical) BOOL vertical;
@property (nonatomic, assign) CGFloat offset;

@end
