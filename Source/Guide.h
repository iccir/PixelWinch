// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Guide : CanvasObject

+ (instancetype) guideVertical:(BOOL)vertical;
+ (instancetype) guideWithOffset:(CGFloat)offset vertical:(BOOL)isVertical;

@property (nonatomic, readonly, getter=isVertical) BOOL vertical;
@property (nonatomic, assign) CGFloat offset;

@end
