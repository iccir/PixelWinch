//
//  GuideLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "GrappleLayer.h"
#import "Guide.h"
#import "Canvas.h"
#import "Grapple.h"
#import "TextLayer.h"
#import "Canvas.h"


@implementation GrappleLayer {
    CALayer   *_sublayer;
    TextLayer *_textLayer;
    CGPoint    _downPoint;
}

@dynamic grapple;


- (id) init
{
    if ((self = [super init])) {
        _sublayer = [CALayer layer];
        [_sublayer setDelegate:self];
        [_sublayer setBackgroundColor:[[NSColor greenColor] CGColor]];

        _textLayer = [TextLayer layer];
        [_textLayer setDelegate:self];
        
        [self addSublayer:_sublayer];
        [self addSublayer:_textLayer];
    }

    return self;
}


- (void) layoutSublayers
{
    Grapple *grapple = [self grapple];
    CGRect   frame   = [self bounds];

    CGFloat offset = ([self contentsScale] > 1) ? 1.5 : 2;

    if ([grapple isVertical]) {
        frame.origin.x = offset;
        frame.size.width = 1;

    } else {
        frame.origin.y = offset;
        frame.size.height = 1;
    }

    [_sublayer setFrame:frame];
    [_textLayer setFrame:frame];
    [_textLayer setDimensions:[[self grapple] rect].size];

    if ([[self grapple] isVertical]) {
        [_textLayer setTextLayerStyle:TextLayerStyleHeightOnly];
    } else {
        [_textLayer setTextLayerStyle:TextLayerStyleWidthOnly];
    }
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
    
    NSInteger threshold = _originalThreshold + larger;
    if (threshold < 0) threshold = 0;
    else if (threshold > 255) threshold = 255;
    
    Grapple *grapple = [self grapple];
    [[grapple canvas] updateGrapple:grapple point:_originalPoint threshold:threshold stopsOnGuides:_originalStopsOnGuides];

    NSString *cursorText = [NSString stringWithFormat:@"%@, %ld", GetStringForFloat([grapple length]), (long)threshold];
    [[CursorInfo sharedInstance] setText:cursorText forKey:@"new-grapple"];
}


#pragma mark - CanvasLayer Overrides

- (BOOL) mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _downPoint = [event locationInWindow];
    [self _updateNewGrappleWithEvent:event point:point];
    return YES;
}


- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        [self _updateNewGrappleWithEvent:event point:point];
    } else {
    
    }
}


- (void) mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point
{
    [[CursorInfo sharedInstance] setText:nil forKey:@"new-grapple"];

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
}


- (void) setNewborn:(BOOL)newborn
{
    [super setNewborn:newborn];
    [self _updateVisibilityOfTextLayer];
}


- (Grapple *) grapple
{
    return (Grapple *)[self canvasObject];
}


@end
