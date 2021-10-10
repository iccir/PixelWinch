//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "CanvasObjectView.h"
#import "CanvasView.h"
#import "CanvasObject.h"
#import "Canvas.h"


typedef NS_ENUM(NSInteger, CanvasObjectMoveConstraintState){
    CanvasObjectMoveConstraintNone,
    CanvasObjectMoveConstraintXAxis,
    CanvasObjectMoveConstraintYAxis
};


@implementation CanvasObjectView {
    CGPoint _moveTrackingMousePoint;
    CanvasObjectMoveConstraintState _moveConstraintState;
    BOOL    _spaceBarModifierDown;

    CanvasObjectView *_duplicateObjectView;
    NSEvent *_duplicateMouseDownEvent;
    NSEvent *_duplicateMouseDragEvent;
}

- (void) preferencesDidChange:(Preferences *)preferences { }


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSEventTypeLeftMouseDown) {
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

    BOOL altOptionDownAtStart = ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagOption) > 0;
    if (altOptionDownAtStart) {
        _duplicateMouseDownEvent = event;
    }

    [self trackWithEvent:event newborn:NO];

    [[self canvasView] didTrackObjectView:self];

    // We have a _duplicateObjectView, hand over control to it
    if (_duplicateObjectView) {
        NSArray *otherEvents = _duplicateMouseDragEvent ? @[ _duplicateMouseDragEvent ] : nil;
        [[self canvasView] willTrackObjectView:_duplicateObjectView];
        [_duplicateObjectView _trackWithStartEvent:_duplicateMouseDownEvent otherEvents:otherEvents newborn:NO];
        [[self canvasView] didTrackObjectView:_duplicateObjectView];
    }

    _duplicateMouseDownEvent = nil;
    _duplicateMouseDragEvent = nil;
    _duplicateObjectView     = nil;
}


- (void) _trackWithStartEvent: (NSEvent *) startEvent
                  otherEvents: (NSArray *) otherEvents
                      newborn: (BOOL) newborn
{
    [self setNewborn:newborn];

    CanvasView *canvasView = [self canvasView];

    __block CGPoint snappedPoint = [canvasView roundedCanvasPointForEvent:startEvent];
    [self startTrackingWithEvent:startEvent point:snappedPoint];

    [[self canvasView] invalidateCursors];

    __block NSEvent *lastDragEvent = nil;

    void (^handleEvent)(NSEvent *event, BOOL *stop) = ^(NSEvent *event, BOOL *stop) {
        NSEventType type = [event type];
        
        *stop = NO;
        
        BOOL isSpaceBarEvent = NO;
        if (type == NSEventTypeKeyDown || type == NSEventTypeKeyUp) {
            isSpaceBarEvent = [[event characters] isEqualToString:@" "];
            
            if (isSpaceBarEvent) {
                BOOL inMoveMode = (type == NSEventTypeKeyDown);
                if (inMoveMode != _inMoveMode) {
                    _inMoveMode = inMoveMode;
                    _canvasObjectRectWhenEnteredMoveMode = [[self canvasObject] rect];
                    _pointWhenEnteredMoveMode = snappedPoint;
                    [self switchTrackingWithEvent:event point:snappedPoint];
                }
            }
        }

        if (type == NSEventTypeLeftMouseUp) {
            snappedPoint = [canvasView roundedCanvasPointForEvent:event];

            if (_inMoveMode) {
                _inMoveMode = NO;
                [self switchTrackingWithEvent:event point:snappedPoint];
            }

            [self endTrackingWithEvent:event point:snappedPoint];
            *stop = YES;
            return;

        } else if (type == NSEventTypeLeftMouseDragged) {
            if (_duplicateMouseDownEvent) {
                _duplicateObjectView = [[self canvasView] duplicateObjectView:self];
                
                if (_duplicateObjectView) {
                    _duplicateMouseDragEvent = event;
                    *stop = YES;
                    return;
                } else {
                    _duplicateMouseDownEvent = nil;
                }
            }
            
            if ([self allowsAutoscroll]) {
                [self autoscroll:event];
            }

            snappedPoint = [canvasView roundedCanvasPointForEvent:event];
            [self continueTrackingWithEvent:event point:snappedPoint];
            lastDragEvent = event;

        } else if ((type == NSEventTypeFlagsChanged || type == NSEventTypeKeyUp || type == NSEventTypeKeyDown) && lastDragEvent) {
            snappedPoint = [canvasView roundedCanvasPointForEvent:lastDragEvent];
            [self continueTrackingWithEvent:lastDragEvent point:snappedPoint];
        }
    };

    for (NSEvent *event in otherEvents) {
        BOOL stop = NO;
        handleEvent(event, &stop);
        if (stop) break;
    }

    while (1) {
        NSEvent *event = [[self window] nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp | NSEventMaskFlagsChanged | NSEventMaskKeyDown | NSEventMaskKeyUp)];
        BOOL stop = NO;
        
        handleEvent(event, &stop);

        if (stop) break;
    }

    if (_duplicateObjectView) {
        return;
    }

    CanvasObject *canvasObject = [self canvasObject];

    if (![canvasObject isValid]) {
        [[canvasObject canvas] removeCanvasObject:canvasObject];
    }

    [self setNewborn:NO];

    [[self canvasView] invalidateCursors];
}


- (void) trackWithEvent:(NSEvent *)event newborn:(BOOL)newborn
{
    [self _trackWithStartEvent:event otherEvents:nil newborn:newborn];
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _moveTrackingMousePoint = [[self canvasView] convertPoint:[event locationInWindow] fromView:nil];
    _moveConstraintState    = CanvasObjectMoveConstraintNone;
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CanvasView *canvasView = [self canvasView];
    CGPoint pointInCanvasView = [canvasView convertPoint:[event locationInWindow] fromView:nil];

    CGPoint deltaPoint = CGPointMake(
        pointInCanvasView.x - _moveTrackingMousePoint.x,
        pointInCanvasView.y - _moveTrackingMousePoint.y
    );

    if ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagShift) {
        if (_moveConstraintState == CanvasObjectMoveConstraintNone) {
            if (fabs(deltaPoint.x) >= fabs(deltaPoint.y)) {
                _moveConstraintState = CanvasObjectMoveConstraintYAxis;
            } else {
                _moveConstraintState = CanvasObjectMoveConstraintXAxis;
            }
        }

        if (_moveConstraintState == CanvasObjectMoveConstraintXAxis) {
            deltaPoint.x = 0;
        } else if (_moveConstraintState == CanvasObjectMoveConstraintYAxis) {
            deltaPoint.y = 0;
        }

    } else {
        _moveConstraintState = CanvasObjectMoveConstraintNone;
    }

    deltaPoint = [canvasView roundedCanvasPointForPoint:deltaPoint];

    NSArray *selectedObjects = [[[self canvasObject] canvas] selectedObjects];
    for (CanvasObject *selectedObject in selectedObjects) {
        [selectedObject performRelativeMoveWithDeltaX:deltaPoint.x deltaY:deltaPoint.y];
    }
}


- (void) switchTrackingWithEvent:(NSEvent *)event point:(CGPoint)point { }

- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point { }

- (void) willSnapshot { }
- (void) didSnapshot { }

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


- (CanvasOrder) canvasOrder
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


- (BOOL) allowsAutoscroll
{
    return YES;
}


- (NSCursor *) cursor
{
    return nil;
}


- (ResizeKnobStyle) resizeKnobStyle
{
    return ResizeKnobStyleNone;
}


- (NSArray *) resizeKnobEdges
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


@end
