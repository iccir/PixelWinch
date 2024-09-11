// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Line : CanvasObject

+ (instancetype) lineVertical:(BOOL)vertical;

- (CGFloat) length;

@property (nonatomic, readonly, getter=isVertical) BOOL vertical;
@property (nonatomic, getter=isPreview) BOOL preview;

@end
