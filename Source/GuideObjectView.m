//
//  GuideLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "GuideObjectView.h"
#import "Guide.h"
#import "Canvas.h"
#import "Line.h"


@interface GuideObjectView () <CALayerDelegate>
@end


@implementation GuideObjectView {
    CALayer *_sublayer;
    NSArray *_grapplesToUpdateStart;
    NSArray *_grapplesToUpdateEnd;
    BOOL     _tracking;
}

@dynamic guide;


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _sublayer = [CALayer layer];

        [_sublayer setDelegate:self];

        [[self layer] addSublayer:_sublayer];
        
        [self _updateLayersAnimated:NO];
    }

    return self;
}


- (void) _updateLayersAnimated:(BOOL)animated
{
    Preferences *preferences = [Preferences sharedInstance];

    if (animated) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        [animation setFromValue:(__bridge id)[_sublayer backgroundColor]];
        [animation setDuration:0.25];
        
        [_sublayer addAnimation:animation forKey:@"backgroundColor"];
    }

    NSColor *color = _tracking ? [preferences activeGuideColor] : [preferences placedGuideColor];
    [_sublayer setBackgroundColor:[color CGColor]];
}


- (NSInteger) canvasOrder
{
    return CanvasOrderGuide;
}


- (void) layoutSubviews
{
    Guide *guide = [self guide];
    CGRect frame = [self bounds];

    CGFloat scale = [[self window] backingScaleFactor];
    CGFloat offset = (scale > 1) ? 1.5 : 2;

    if ([guide isVertical]) {
        frame.origin.x = offset;
        frame.size.width = 1;

    } else {
        frame.origin.y = offset;
        frame.size.height = 1;
    }

    [_sublayer setFrame:frame];
}


- (void) preferencesDidChange:(Preferences *)preferences
{
    [self _updateLayersAnimated:YES];
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _tracking = YES;
    [self _updateLayersAnimated:YES];

    Preferences *preferences = [Preferences sharedInstance];
    [_sublayer setBackgroundColor:[[preferences activeGuideColor] CGColor]];
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    Guide  *guide  = [self guide];
    CGFloat offset = [guide isVertical] ? point.x : point.y;

    [guide setOffset:offset];
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _grapplesToUpdateStart = nil;
    _grapplesToUpdateEnd   = nil;

    _tracking = NO;
    [self _updateLayersAnimated:YES];
}


- (NSCursor *) cursor
{
    if ([[self guide] isVertical]) {
        return [NSCursor resizeLeftRightCursor];
    } else {
        return [NSCursor resizeUpDownCursor];
    }
}


- (CGRect) rectForCanvasLayout
{
    Guide  *guide  = [self guide];
    CGFloat offset = [guide offset];
    
    if ([guide isVertical]) {
        return CGRectMake(offset, -INFINITY, 0, INFINITY);
    } else {
        return CGRectMake(-INFINITY, offset, INFINITY, 0);
    }
}


- (NSEdgeInsets) paddingForCanvasLayout
{
    if ([[self guide] isVertical]) {
        return NSEdgeInsetsMake(0, 2, 0, 2);
    } else {
        return NSEdgeInsetsMake(2, 0, 2, 0);
    }
}


- (BOOL) allowsAutoscroll
{
    return NO;
}


#pragma mark - Accessors

- (void) setGuide:(Guide *)guide
{
    [self setCanvasObject:guide];
}


- (Guide *) guide
{
    return (Guide *)[self canvasObject];
}


@end
