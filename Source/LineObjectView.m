//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "LineObjectView.h"

#import "Guide.h"
#import "Canvas.h"
#import "Line.h"
#import "Canvas.h"
#import "CursorAdditions.h"


@implementation LineObjectView {
    BOOL _tracking;
}

@dynamic line;


#pragma mark - Superclass Overrides

- (void) drawRect:(NSRect)dirtyRect
{
    Line   *line  = [self line];
    CGRect  frame = [self bounds];

    CGSize padding = [self paddingForCanvasLayout];
    CGRect insetRect = CGRectInset(frame, padding.width, padding.height);
    
    CGRect startAnchorFrame = insetRect;
    CGRect endAnchorFrame = insetRect;
    
    BOOL showAnchors = NO;

    if ([line isVertical]) {
        frame.origin.x = ScaleRound((frame.size.width - 1) / 2, 2);
        frame.size.width = 1;
        
        startAnchorFrame.origin.y = CGRectGetMinY(frame);
        startAnchorFrame.size.height = 1;

        endAnchorFrame.origin.y = CGRectGetMaxY(frame) - 1;
        endAnchorFrame.size.height = 1;
        
        showAnchors = startAnchorFrame.size.width > 5;
        
    } else {
        frame.origin.y = ScaleRound((frame.size.height - 1) / 2, 2);
        frame.size.height = 1;

        startAnchorFrame.origin.x = CGRectGetMinX(frame);
        startAnchorFrame.size.width = 1;

        endAnchorFrame.origin.x = CGRectGetMaxX(frame) - 1;
        endAnchorFrame.size.width = 1;

        showAnchors = startAnchorFrame.size.height > 4;
    }
   
    Preferences *preferences = [Preferences sharedInstance];

    NSColor *lineColor = nil;

    if ([[self line] isPreview] || (_tracking && [self isNewborn])) {
        lineColor = [preferences previewGrappleColor];
    } else {
        lineColor = [preferences placedGrappleColor];
    }

    [lineColor set];
    NSRectFill(frame);

    if (showAnchors) {
        NSRectFill(startAnchorFrame);
        NSRectFill(endAnchorFrame);
    }
}

- (NSCursor *) cursor
{
    return [NSCursor arrowCursor];
}


- (ResizeKnobStyle) resizeKnobStyle
{
    return ResizeKnobStyleRectangular;
}


- (NSArray *) resizeKnobEdges
{
    if ([[self line] isVertical]) {
        return @[ @( ObjectEdgeTop  ), @( ObjectEdgeBottom ) ];
    } else {
        return @[ @( ObjectEdgeLeft ), @( ObjectEdgeRight  ) ];
    }
}


- (CanvasOrder) canvasOrder
{
    return [[self line] isPreview] ? CanvasOrderPreviewLine : CanvasOrderLine;
}


#pragma mark - CanvasLayer Overrides

- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _tracking = YES;
    [self setNeedsDisplay:YES];

    if (![self isNewborn]) {
        [super startTrackingWithEvent:event point:point];
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _tracking = NO;
    [self setNeedsDisplay:YES];

    if ([self isNewborn]) {
        [[self canvasView] makeVisibleAndPopInLabelForView:self];
    } else {
        [super endTrackingWithEvent:event point:point];
    }
}


- (CGRect) rectForCanvasLayout
{
    return [[self line] rect];
}


- (CGSize) paddingForCanvasLayout
{
    if ([[self line] isVertical]) {
        return CGSizeMake(1, 0);
    } else {
        return CGSizeMake(0, 1);
    }
}


#pragma mark - Accessors

- (void) setLine:(Line *)line
{
    [self setCanvasObject:line];
    [self setNeedsDisplay:YES];
}


- (void) setNewborn:(BOOL)newborn
{
    [super setNewborn:newborn];
    [self setNeedsDisplay:YES];
}


- (NSString *) groupName
{
    return @"grapples";
}


- (MeasurementLabelStyle) measurementLabelStyle
{
    if ([[self line] isVertical]) {
        return MeasurementLabelStyleHeightOnly;
    } else {
        return MeasurementLabelStyleWidthOnly;
    }
}


- (BOOL) isMeasurementLabelHidden
{
    return [self isNewborn] || [[self line] isPreview];
}


- (Line *) line
{
    return (Line *)[self canvasObject];
}


@end
