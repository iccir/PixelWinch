// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@class Rectangle;

@interface RectangleObjectView : CanvasObjectView
@property (nonatomic, strong) Rectangle *rectangle;
@end
