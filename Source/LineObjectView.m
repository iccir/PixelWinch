//
//  GuideLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "LineObjectView.h"

#import "Guide.h"
#import "Canvas.h"
#import "Line.h"
#import "Canvas.h"
#import "CursorAdditions.h"

@implementation LineObjectView {
    CALayer   *_lineLayer;
    CALayer   *_startAnchorLayer;
    CALayer   *_endAnchorLayer;

    CGPoint    _downPoint;
    CGPoint    _originalPoint;
    
    BOOL _tracking;
}

@dynamic line;


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _lineLayer = [CALayer layer];
        [_lineLayer setDelegate:self];

        _startAnchorLayer = [CALayer layer];
        [_startAnchorLayer setDelegate:self];

        _endAnchorLayer = [CALayer layer];
        [_endAnchorLayer setDelegate:self];

        [[self layer] addSublayer:_lineLayer];
        [[self layer] addSublayer:_endAnchorLayer];
        [[self layer] addSublayer:_startAnchorLayer];
        
        [self _updateLayersAnimated:NO];
    }

    return self;
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


- (NSInteger) canvasOrder
{
    return [[self line] isPreview] ? CanvasOrderPreviewLine : CanvasOrderLine;
}


- (void) willMoveToWindow:(NSWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    CGFloat scale = [newWindow backingScaleFactor];
    
    [_lineLayer        setContentsScale:scale];
    [_startAnchorLayer setContentsScale:scale];
    [_endAnchorLayer   setContentsScale:scale];
}


- (void) layoutSubviews
{
    Line   *line  = [self line];
    CGRect  frame = [self bounds];

    XUIEdgeInsets insets = [self paddingForCanvasLayout];
    CGRect insetRect = XUIEdgeInsetsInsetRect(frame, insets);

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
    
    [_lineLayer setFrame:frame];

    [_startAnchorLayer setFrame:startAnchorFrame];
    [_endAnchorLayer   setFrame:endAnchorFrame];

    [_startAnchorLayer setHidden:!showAnchors];
    [_endAnchorLayer   setHidden:!showAnchors];
}


- (void) preferencesDidChange:(Preferences *)preferences
{
    [self _updateLayersAnimated:NO];
}


#pragma mark - Private Methods

- (void) _updateLayersAnimated:(BOOL)animated
{
    Preferences *preferences = [Preferences sharedInstance];

    NSColor *lineColor = nil;

    if ([[self line] isPreview] || (_tracking && [self isNewborn])) {
        lineColor = [preferences previewGrappleColor];
    } else {
        lineColor = [preferences placedGrappleColor];
    }

    if (animated) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        [animation setFromValue:(__bridge id)[_lineLayer backgroundColor]];
        [animation setDuration:0.25];
        
        [_lineLayer        addAnimation:animation forKey:@"backgroundColor"];
        [_startAnchorLayer addAnimation:animation forKey:@"backgroundColor"];
        [_endAnchorLayer   addAnimation:animation forKey:@"backgroundColor"];
    }

    [_lineLayer        setBackgroundColor:[lineColor CGColor]];
    [_startAnchorLayer setBackgroundColor:[lineColor CGColor]];
    [_endAnchorLayer   setBackgroundColor:[lineColor CGColor]];
}


#pragma mark - CanvasLayer Overrides

- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _downPoint = [event locationInWindow];
    _originalPoint = point;

    _tracking = YES;
    [self _updateLayersAnimated:YES];

    if (![self isNewborn]) {
        [super startTrackingWithEvent:event point:point];
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _tracking = NO;
    [self _updateLayersAnimated:YES];

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


- (XUIEdgeInsets) paddingForCanvasLayout
{
    if ([[self line] isVertical]) {
        return XUIEdgeInsetsMake(0, 1, 0, 1);
    } else {
        return XUIEdgeInsetsMake(1, 0, 1, 0);
    }
}


#pragma - Accessors

- (void) setLine:(Line *)line
{
    [self setCanvasObject:line];
    [self _updateLayersAnimated:NO];
}


- (void) setNewborn:(BOOL)newborn
{
    [super setNewborn:newborn];
    [self _updateLayersAnimated:NO];
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
