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
    if ([[self grapple] isVertical]) {
        return [NSCursor winch_resizeEastWestCursor];
    } else {
        return [NSCursor winch_resizeNorthSouthCursor];
    }
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


- (void) layoutSubviews
{
    Grapple *grapple = [self grapple];
    CGRect   frame   = [self bounds];

    CGFloat offset = ([self contentScaleFactor] > 1) ? 1.5 : 2;

    if ([grapple isVertical]) {
        frame.origin.x = offset;
        frame.size.width = 1;

    } else {
        frame.origin.y = offset;
        frame.size.height = 1;
    }

    [_lineLayer setFrame:frame];
    [_textLayer setFrame:frame];
    [_textLayer setDimensions:[[self grapple] rect].size];

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

    if ([[self grapple] isPreview]) {
        lineColor = [NSColor redColor]; // preferences previewGrappleColor];
    } else if (_tracking) {
        lineColor = [preferences activeGrappleColor];
    } else {
        lineColor = [preferences placedGrappleColor];
    }

    [_lineLayer setBackgroundColor:[lineColor CGColor]];
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
    }
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        [self _updateNewGrappleWithEvent:event point:point];
    } else {
        
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    [[CursorInfo sharedInstance] setText:nil forKey:@"new-grapple"];

    _tracking = NO;
    [self _updateLayersAnimated:YES];

    if ([self isNewborn]) {
        AddPopInAnimation(_textLayer, 0.25);
    }
}


- (CGRect) rectForCanvasLayout
{
    return [[self grapple] rect];
}


- (NSEdgeInsets) paddingForCanvasLayout
{
    if ([[self grapple] isVertical]) {
        return NSEdgeInsetsMake(0, 2, 0, 2);
    } else {
        return NSEdgeInsetsMake(2, 0, 2, 0);
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


- (Grapple *) grapple
{
    return (Grapple *)[self canvasObject];
}


@end
