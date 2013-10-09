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


@implementation GrappleLayer {
    CALayer *_sublayer;
}

@dynamic grapple;


- (id) init
{
    if ((self = [super init])) {
        _sublayer = [CALayer layer];

        [_sublayer setDelegate:self];
        [_sublayer setBackgroundColor:[[NSColor greenColor] CGColor]];

        [self addSublayer:_sublayer];
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
}


- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
}


- (void) mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point
{
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
}

- (Grapple *) grapple
{
    return (Grapple *)[self canvasObject];
}

@end
