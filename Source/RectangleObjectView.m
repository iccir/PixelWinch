//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "RectangleObjectView.h"
#import "Rectangle.h"
#import "MeasurementLabel.h"

#import <objc/objc-runtime.h>


@implementation RectangleObjectView {
    CGPoint _downPoint;
}

@dynamic rectangle;


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];

    CGRect bounds = [self bounds];

    CGFloat onePixel = [[self window] backingScaleFactor] > 1 ? 0.5 : 1.0;
    CGRect insetBounds = CGRectInset(bounds, onePixel, onePixel);

    Preferences *preferences = [Preferences sharedInstance];

    [[preferences placedRectangleFillColor] set];
    CGContextFillRect(context, bounds);
    
    [[preferences placedRectangleBorderColor] set];
    CGContextAddRect(context, bounds);
    CGContextAddRect(context, insetBounds);
    CGContextEOFillPath(context);
}


- (CGRect) rectForCanvasLayout
{
    return [[self rectangle] rect];
}


- (NSCursor *) cursor
{
    return [NSCursor arrowCursor];
}


- (ResizeKnobStyle) resizeKnobStyle
{
    return ResizeKnobStyleCircular;
}



- (NSArray *) resizeKnobEdges
{
    return @[
        @( ObjectEdgeTopLeft     ),
        @( ObjectEdgeTop         ),
        @( ObjectEdgeTopRight    ),
        @( ObjectEdgeLeft        ),
        @( ObjectEdgeRight       ),
        @( ObjectEdgeBottomLeft  ),
        @( ObjectEdgeBottom      ),
        @( ObjectEdgeBottomRight )
    ];
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        _downPoint = point;
        [[self rectangle] setRect:CGRectMake(_downPoint.x, _downPoint.y, 0, 0)];
    } else {
        [super startTrackingWithEvent:event point:point];
    }
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        CGRect newRect = CGRectMake(
            _downPoint.x,
            _downPoint.y,
            point.x - _downPoint.x,
            point.y - _downPoint.y
        );

        if ([self inMoveMode]) {
            CGPoint startPoint = [self pointWhenEnteredMoveMode];
            CGRect  objectRect = [self canvasObjectRectWhenEnteredMoveMode];

            newRect = objectRect;
            newRect.origin.x += (point.x - startPoint.x);
            newRect.origin.y += (point.y - startPoint.y);
        }

        Rectangle *rectangle = [self rectangle];

        if ([NSEvent modifierFlags] & NSEventModifierFlagShift) {
            if (newRect.size.width  > newRect.size.height) newRect.size.height = newRect.size.width;
            if (newRect.size.height > newRect.size.width)  newRect.size.width  = newRect.size.height;
        }
        
        [rectangle setRect:newRect];
        
        CursorInfo *cursorInfo = [CursorInfo sharedInstance];
        
        CGSize size = CGSizeMake(fabs(newRect.size.width), fabs(newRect.size.height));
        [cursorInfo setText:GetDisplayStringForSize(size) forKey:@"new-rectangle"];
        
    } else {
        [super continueTrackingWithEvent:event point:point];
    }
}


- (void) switchTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        if (![self inMoveMode]) {
            NSRect rect = [[self canvasObject] rect];
            _downPoint = GetFurthestCornerInRect(rect, point);
        }
    } else {
        [super switchTrackingWithEvent:event point:point];
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        [[CursorInfo sharedInstance] setText:nil forKey:@"new-rectangle"];
        [[self canvasView] makeVisibleAndPopInLabelForView:self];

    } else {
        [super endTrackingWithEvent:event point:point];
    }
}


#pragma mark - Accessors

- (void) setRectangle:(Rectangle *)rectangle
{
    [self setCanvasObject:rectangle];
}


- (Rectangle *) rectangle
{
    return (Rectangle *)[self canvasObject];
}


- (MeasurementLabelStyle) measurementLabelStyle
{
    return MeasurementLabelStyleBoth;
}


- (BOOL) isMeasurementLabelHidden
{
    return [self isNewborn];
}


- (void) setNewborn:(BOOL)newborn
{
    [super setNewborn:newborn];
}


@end
