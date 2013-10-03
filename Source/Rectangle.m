
//
//  Rectangle.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Rectangle.h"
#import "Canvas.h"

@implementation Rectangle

+ (instancetype) rectangle
{
    return [[self alloc] init];
}


- (void) setRect:(CGRect)rect
{
    if (!CGRectEqualToRect(_rect, rect)) {
        _rect = rect;
        [[self canvas] objectDidUpdate:self];
    }
}


- (void) moveEdge:(CGRectEdge)edge value:(CGFloat)value
{
    CGRect rect = [self rect];
    rect = GetRectByAdjustingEdge(rect, edge, value);
    [self setRect:rect];
}

@end
