//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "GuideObjectView.h"
#import "Guide.h"
#import "Canvas.h"
#import "Line.h"


@interface GuideObjectView () <CALayerDelegate>
@end


@implementation GuideObjectView {
    BOOL     _tracking;
}

@dynamic guide;


- (void) drawRect:(NSRect)dirtyRect
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

    Preferences *preferences = [Preferences sharedInstance];

    NSColor *color = _tracking ? [preferences activeGuideColor] : [preferences placedGuideColor];
    [color set];
    
    NSRectFill(frame);
}


- (CanvasOrder) canvasOrder
{
    return CanvasOrderGuide;
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _tracking = YES;
    [self setNeedsDisplay:YES];
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    Guide  *guide  = [self guide];
    CGFloat offset = [guide isVertical] ? point.x : point.y;

    [guide setOffset:offset];
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _tracking = NO;
    [self setNeedsDisplay:YES];
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


- (CGSize) paddingForCanvasLayout
{
    if ([[self guide] isVertical]) {
        return CGSizeMake(2, 0);
    } else {
        return CGSizeMake(0, 2);
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
