//
//  GuideLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "GuideLayer.h"
#import "Guide.h"
#import "Canvas.h"


@implementation GuideLayer {
    CALayer *_sublayer;
}

@dynamic guide;


- (id) init
{
    if ((self = [super init])) {
        _sublayer = [CALayer layer];

        [_sublayer setDelegate:self];

        [self addSublayer:_sublayer];
        
        [self _updateLayers];
    }

    return self;
}


- (void) _updateLayers
{
    Preferences *preferences = [Preferences sharedInstance];
    [_sublayer setBackgroundColor:[[preferences placedGuideColor] CGColor]];
}


- (void) layoutSublayers
{
    Guide *guide = [self guide];
    CGRect frame = [self bounds];

    CGFloat offset = ([self contentsScale] > 1) ? 1.5 : 2;

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
    [self _updateLayers];
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point
{
    return YES;
}


- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    Guide *guide = [self guide];
    
    if ([guide isVertical]) {
        [guide setOffset:point.x];
    } else {
        [guide setOffset:point.y];
    }
}


- (void) mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point
{
    Guide *guide = [self guide];

    if ([guide isOutOfBounds]) {
        [[guide canvas] removeGuide:guide];
    }
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


#pragma - Accessors

- (void) setGuide:(Guide *)guide
{
    [self setCanvasObject:guide];
}

- (Guide *) guide
{
    return (Guide *)[self canvasObject];
}

@end
