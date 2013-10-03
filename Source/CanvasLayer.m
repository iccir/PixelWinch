//
//  CanvasLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "CanvasLayer.h"

@implementation CanvasLayer

- (BOOL) mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point { return NO; }
- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point { }
- (void) mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point   { }

- (NSCursor *) cursor
{
    return nil;
}


- (CGRect) rectForCanvasLayout
{
    return CGRectZero;
}


- (NSEdgeInsets) paddingForCanvasLayout
{
    return NSEdgeInsetsMake(0, 0, 0, 0);
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return [[self delegate] actionForLayer:self forKey:event];
}


- (SnappingPolicy) verticalSnappingPolicy
{
    return SnappingPolicyToPixelEdge;
}


- (SnappingPolicy) horizontalSnappingPolicy
{
    return SnappingPolicyToPixelEdge;
}


@end
