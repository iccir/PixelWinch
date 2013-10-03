//
//  Marquee.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Marquee.h"
#import "Canvas.h"


@implementation Marquee

- (void) setRect:(CGRect)rect
{
    if (!CGRectEqualToRect(_rect, rect)) {
        _rect = rect;
        [[self canvas] objectDidUpdate:self];
    }
}

@end
