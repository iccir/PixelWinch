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
    
    if ([event clickCount] == 2) {
        [[self canvasView] objectViewDoubleClick:self];
        return;
    }

    if (![[self canvasView] shouldTrackObjectView:self]) {
        [super mouseDown:event];
        return;
    }

    [[self canvasView] willTrackObjectView:self];

    [self trackWithEvent:event newborn:NO];

    [[self canvasView] didTrackObjectView:self];
}


- (void) trackWithEvent:(NSEvent *)event newborn:(BOOL)newborn
{
    [self setNewborn:newborn];

    CanvasView *canvasView = [self canvasView];

    CGPoint snappedPoint = [canvasView roundedCanvasPointForEvent:event];
    [self startTrackingWithEvent:event point:snappedPoint];
    
    
    NSEvent *lastDragEvent = nil;

    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask)];
            
        NSEventType type = [event type];
        if (type == NSLeftMouseUp) {
            snappedPoint = [canvasView roundedCanvasPointForEvent:event];
            [self endTrackingWithEvent:event point:snappedPoint];
            break;

        } else if (type == NSLeftMouseDragged) {
            snappedPoint = [canvasView roundedCanvasPointForEvent:event];
            [self continueTrackingWithEvent:event point:snappedPoint];
            lastDragEvent = event;

        } else if ((type == NSFlagsChanged) && lastDragEvent) {
            snappedPoint = [canvasView roundedCanvasPointForEvent:lastDragEvent];
            [self continueTrackingWithEvent:lastDragEvent point:snappedPoint];
        }
    }

    CanvasObject *canvasObject = [self canvasObject];

    if (![canvasObject isValid]) {
        [[canvasObject canvas] removeCanvasObject:canvasObject];
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
    CanvasView *canvasView = [self canvasView];
    CGPoint pointInCanvasView = [canvasView convertPoint:[event locationInWindow] fromView:nil];

    CGPoint deltaPoint = CGPointMake(
        pointInCanvasView.x - _moveTrackingMousePoint.x,
        pointInCanvasView.y - _moveTrackingMousePoint.y
    );

    deltaPoint = [canvasView roundedCanvasPointForPoint:deltaPoint];

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


- (MeasurementLabelStyle) measurementLabelStyle
{
    return MeasurementLabelStyleNone;
}


- (BOOL) isMeasurementLabelHidden
{
    return YES;
}


- (NSCursor *) cursor
{
    return nil;
}


- (NSArray *) resizeKnobEdges
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


@end
