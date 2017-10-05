//  (c) 2013-2017, Ricci Adams.  All rights reserved.


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
        [GetRGBColor(0x101010, 1.0) set];
        CGContextFillRect(context, bounds);

        [GetRGBColor(0x262626, 1.0) set];
        CGContextFillRect(context, CGRectInset(bounds, onePixel, onePixel));

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
