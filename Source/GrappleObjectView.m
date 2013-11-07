//
//  GuideLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "GrappleObjectView.h"

#import "Guide.h"
#import "Canvas.h"
#import "Grapple.h"
#import "TextLayer.h"
#import "Canvas.h"
#import "CursorAdditions.h"

@implementation GrappleObjectView {
    CALayer   *_lineLayer;
    CALayer   *_startAnchorLayer;
    CALayer   *_endAnchorLayer;

    TextLayer *_textLayer;
    CGPoint    _downPoint;
    CGPoint    _originalPoint;
    
    BOOL _tracking;
}

@dynamic grapple;


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _lineLayer = [CALayer layer];
        [_lineLayer setDelegate:self];

        _startAnchorLayer = [CALayer layer];
        [_startAnchorLayer setDelegate:self];

        _endAnchorLayer = [CALayer layer];
        [_endAnchorLayer setDelegate:self];

        _textLayer = [TextLayer layer];
        [_textLayer setDelegate:self];
        
        [[self layer] addSublayer:_lineLayer];
        [[self layer] addSublayer:_endAnchorLayer];
        [[self layer] addSublayer:_startAnchorLayer];
        [[self layer] addSublayer:_textLayer];
        
        [self _updateLayersAnimated:NO];
    }

    return self;
}


- (NSCursor *) cursor
{
    return [NSCursor arrowCursor];
}


- (NSArray *) resizeKnobTypes
{
    if ([[self grapple] isVertical]) {
        return @[ @( ResizeKnobTop  ), @( ResizeKnobBottom ) ];
    } else {
        return @[ @( ResizeKnobLeft ), @( ResizeKnobRight  ) ];
    }
}


- (NSInteger) canvasOrder
{
    return [[self grapple] isPreview] ? CanvasOrderPreviewGrapple : CanvasOrderGrapple;
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
    Grapple *grapple = [self grapple];
    CGRect   frame   = [self bounds];

    XUIEdgeInsets insets = [self paddingForCanvasLayout];
    CGRect insetRect = XUIEdgeInsetsInsetRect(frame, insets);

    CGRect startAnchorFrame = insetRect;
    CGRect endAnchorFrame = insetRect;
    
    BOOL showAnchors = NO;

    if ([grapple isVertical]) {
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
    [_textLayer setFrame:frame];
    [_textLayer setDimensions:[[self grapple] rect].size];

    [_startAnchorLayer setFrame:startAnchorFrame];
    [_endAnchorLayer   setFrame:endAnchorFrame];

    [_startAnchorLayer setHidden:!showAnchors];
    [_endAnchorLayer   setHidden:!showAnchors];
    
    if ([[self grapple] isVertical]) {
        [_textLayer setTextLayerStyle:TextLayerStyleHeightOnly];
    } else {
        [_textLayer setTextLayerStyle:TextLayerStyleWidthOnly];
    }
}


- (void) preferencesDidChange:(Preferences *)preferences
{
    [self _updateLayersAnimated:NO];
}


#pragma mark - Private Methods

- (void) _updateVisibilityOfTextLayer
{
    [_textLayer setHidden:([self isNewborn] || [[self grapple] isPreview])];
}


- (void) _updateNewGrappleWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CGPoint currentPoint = [event locationInWindow];
    
    CGFloat xDelta = currentPoint.x - _downPoint.x;
    CGFloat yDelta = currentPoint.y - _downPoint.y;
    
    CGFloat larger = (xDelta > yDelta) ? xDelta : yDelta;
    
    NSInteger threshold  = _originalThreshold + larger;
    if (threshold < 0) threshold = 0;
    else if (threshold > 255) threshold = 255;

    NSString *cursorText = nil;

    Grapple *grapple = [self grapple];
    [[grapple canvas] updateGrapple:grapple point:_originalPoint threshold:threshold];

    if (threshold != _originalThreshold) {
        CGFloat percent = round((threshold / 255.0f) * 100);
        cursorText = [NSString stringWithFormat:@"%@ %C %g%%", GetStringForFloat([grapple length]), (unichar)0x2014, percent];
    } else {
        cursorText = GetStringForFloat([grapple length]);
    }
        
    [[CursorInfo sharedInstance] setText:cursorText forKey:@"new-grapple"];
}


- (void) _updateLayersAnimated:(BOOL)animated
{
    Preferences *preferences = [Preferences sharedInstance];

    NSColor *lineColor = nil;

    if ([[self grapple] isPreview] || (_tracking && [self isNewborn])) {
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

    if ([self isNewborn]) {
        [self _updateNewGrappleWithEvent:event point:point];
    } else {
        [super startTrackingWithEvent:event point:point];
    }
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        [self _updateNewGrappleWithEvent:event point:point];
    } else {
        [super continueTrackingWithEvent:event point:point];
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    [[CursorInfo sharedInstance] setText:nil forKey:@"new-grapple"];

    _tracking = NO;
    [self _updateLayersAnimated:YES];

    if ([self isNewborn]) {
        AddPopInAnimation(_textLayer, 0.25);
    } else {
        [super endTrackingWithEvent:event point:point];
    }
}


- (CGRect) rectForCanvasLayout
{
    return [[self grapple] rect];
}


- (XUIEdgeInsets) paddingForCanvasLayout
{
    if ([[self grapple] isVertical]) {
        return XUIEdgeInsetsMake(0, 1, 0, 1);
    } else {
        return XUIEdgeInsetsMake(1, 0, 1, 0);
    }
}


#pragma - Accessors

- (void) setGrapple:(Grapple *)grapple
{
    [self setCanvasObject:grapple];
    [self _updateVisibilityOfTextLayer];
    [self _updateLayersAnimated:NO];
}


- (void) setNewborn:(BOOL)newborn
{
    [super setNewborn:newborn];
    [self _updateVisibilityOfTextLayer];
    [self _updateLayersAnimated:NO];
}


- (NSString *) groupName
{
    return @"grapples";
}


- (Grapple *) grapple
{
    return (Grapple *)[self canvasObject];
}


@end
