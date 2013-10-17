//
//  BlackScroller.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-16.
//
//

#import "BlackScroller.h"

@implementation BlackScroller

+ (BOOL) isCompatibleWithOverlayScrollers
{
    return self == [BlackScroller class];
}

- (BOOL) isVertical
{
    CGRect bounds = [self bounds];
    return bounds.size.height > bounds.size.width;
}


- (void) drawKnob
{
    CGRect knobRect = [self rectForPart:NSScrollerKnob];
    
    if ([self isVertical]) {
        knobRect = CGRectInset(knobRect, 5, 2);
    } else {
        knobRect = CGRectInset(knobRect, 2, 5);
    }

    CGFloat radius = knobRect.size.width < knobRect.size.height ? knobRect.size.width : knobRect.size.height;
    radius /= 2;

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:knobRect xRadius:radius yRadius:radius];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
    [path fill];
}


- (void) drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    [GetDarkWindowColor() set];
    CGContextFillRect(context, slotRect);

    CGRect bounds = [self bounds];
    CGFloat onePixel = [[self window] backingScaleFactor] > 1 ? 0.5 : 1.0;

    BOOL vertical = [self isVertical];

    if (vertical) {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:GetDarkWindowColor()];
        [gradient drawInRect:bounds angle:0];

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, 0, onePixel, bounds.size.height));

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(bounds.size.width - onePixel, 0, onePixel, bounds.size.height));

    } else {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:GetDarkWindowColor()];
        [gradient drawInRect:bounds angle:90];

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, 0, bounds.size.width, onePixel));

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, bounds.size.height - onePixel, bounds.size.width, onePixel));
    }

    CGContextSetShadowWithColor(context, CGSizeZero, 2, [GetRGBColor(0, 1.0) CGColor]);
    
    if (vertical) {
        CGContextFillRect(context, CGRectMake(-slotRect.size.width,  -slotRect.size.width,  slotRect.size.width * 3, slotRect.size.width));
    } else {
        CGContextFillRect(context, CGRectMake(-slotRect.size.height, -slotRect.size.height, slotRect.size.height, slotRect.size.height * 3));
    }
}


@end
