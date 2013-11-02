//
//  CanvasLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "CanvasObjectView.h"
#import "CanvasView.h"
#import "CanvasObject.h"
#import "Canvas.h"


@implementation CanvasObjectView {
    CGPoint _moveTrackingOriginPoint;
    CGPoint _moveTrackingMousePoint;
}

- (void) preferencesDidChange:(Preferences *)preferences { }


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        [super mouseDown:event];
        return;
    }

    if (![[self canvasView] shouldTrackObjectView:self]) {
        [super mouseDown:event];
        return;
    }

    [self trackWithEvent:event newborn:NO];

    [[self canvasView] didTrackObjectView:self];
}


- (void) trackWithEvent:(NSEvent *)event newborn:(BOOL)newborn
{
    [self setNewborn:newborn];

    CGPoint snappedPoint = [self snappedPointForEvent:event];
    [self startTrackingWithEvent:event point:snappedPoint];
    
    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            
        NSEventType type = [event type];
        if (type == NSLeftMouseUp) {
            snappedPoint = [self snappedPointForEvent:event];
            [self endTrackingWithEvent:event point:snappedPoint];
            break;

        } else if (type == NSLeftMouseDragged) {
            snappedPoint = [self snappedPointForEvent:event];
            [self continueTrackingWithEvent:event point:snappedPoint];
        }
    }

    CanvasObject *canvasObject = [self canvasObject];

    if (![canvasObject isValid]) {
        [[canvasObject canvas] removeObject:canvasObject];
    }

    [self setNewborn:NO];

    [[self canvasView] invalidateCursors];
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CanvasObject *canvasObject = [self canvasObject];
    _moveTrackingOriginPoint = canvasObject ? [canvasObject rect].origin : CGPointZero;
    _moveTrackingMousePoint = [[self canvasView] convertPoint:[event locationInWindow] fromView:nil];
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CGPoint pointInCanvasView = [[self canvasView] convertPoint:[event locationInWindow] fromView:nil];

    CGPoint deltaPoint = CGPointMake(
        pointInCanvasView.x - _moveTrackingMousePoint.x,
        pointInCanvasView.y - _moveTrackingMousePoint.y
    );

    deltaPoint = [self snappedPointForPoint:deltaPoint];

    CanvasObject *canvasObject = [self canvasObject];

    CGRect rect = [canvasObject rect];
    rect.origin.x = _moveTrackingOriginPoint.x + deltaPoint.x;
    rect.origin.y = _moveTrackingOriginPoint.y + deltaPoint.y;
    
    [[self canvasObject] setRect:rect];
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point { }


- (CanvasView *) canvasView
{
    NSView *superview = [self superview];

    while (superview) {
        if ([superview isKindOfClass:[CanvasView class]]) {
            break;
        }
        
        superview = [superview superview];
    }

    return (CanvasView *)superview;
}


- (NSInteger) canvasOrder
{
    return CanvasOrderNormal;
}


- (NSCursor *) cursor
{
    return nil;
}


- (NSArray *) resizeKnobTypes
{
    return nil;
}


- (CGRect) rectForCanvasLayout
{
    return CGRectZero;
}


- (XUIEdgeInsets) paddingForCanvasLayout
{
    return XUIEdgeInsetsZero;
}


- (CGPoint) snappedPointForEvent:(NSEvent *)event
{
    SnappingPolicy horizontalSnappingPolicy = [self horizontalSnappingPolicy];
    SnappingPolicy verticalSnappingPolicy   = [self verticalSnappingPolicy];
    
    return [[self canvasView] canvasPointForEvent: event
                         horizontalSnappingPolicy: horizontalSnappingPolicy
                           verticalSnappingPolicy: verticalSnappingPolicy];
}


- (CGPoint) snappedPointForPoint:(CGPoint)inPoint
{
    SnappingPolicy horizontalSnappingPolicy = [self horizontalSnappingPolicy];
    SnappingPolicy verticalSnappingPolicy   = [self verticalSnappingPolicy];
    
    return [[self canvasView] canvasPointForPoint: inPoint
                         horizontalSnappingPolicy: horizontalSnappingPolicy
                           verticalSnappingPolicy: verticalSnappingPolicy];
}


- (SnappingPolicy) horizontalSnappingPolicy
{
    return SnappingPolicyToPixelEdge;
}


- (SnappingPolicy) verticalSnappingPolicy
{
    return SnappingPolicyToPixelEdge;
}


@end
