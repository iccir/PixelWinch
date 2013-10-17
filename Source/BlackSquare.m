//
//  BlackSquare.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-17.
//
//

#import "BlackSquare.h"

@implementation BlackSquare

- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGRect bounds = [self bounds];

    [GetDarkWindowColor() set];
    CGContextFillRect(context, bounds);

    CGFloat onePixel = [[self window] backingScaleFactor] > 1 ? 0.5 : 1.0;

    if ([[self superview] isKindOfClass:[NSScrollView class]]) {
        CGPoint point = CGPointMake(0, bounds.size.height);
        CGFloat radius = bounds.size.height > bounds.size.width ? bounds.size.height : bounds.size.width;

        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:GetDarkWindowColor()];
        [gradient drawFromCenter:point radius:0 toCenter:point radius:radius options:NSGradientDrawsAfterEndingLocation];

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, bounds.size.height - onePixel, onePixel, onePixel));
        CGContextFillRect(context, CGRectMake(bounds.size.width - onePixel, 0, onePixel, bounds.size.height));
        CGContextFillRect(context, CGRectMake(0, 0, bounds.size.width - onePixel, onePixel));

    } else {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:GetDarkWindowColor()];
        [gradient drawInRect:bounds angle:-90];
        
        [GetRGBColor(0, 0.5) set];
        NSBezierPath *outerRect = [NSBezierPath bezierPathWithRect:bounds];
        NSBezierPath *innerRect = [NSBezierPath bezierPathWithRect:NSInsetRect(bounds, onePixel, onePixel)];
        
        [outerRect appendBezierPath:[innerRect bezierPathByReversingPath]];
        
        [outerRect fill];
    }
}


@end
