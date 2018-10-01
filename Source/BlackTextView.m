//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "BlackTextView.h"

@implementation BlackTextView

- (void) drawRect:(NSRect)dirtyRect
{
    WithWhiteOnBlackTextMode(^{
        [super drawRect:dirtyRect];
    });
}

- (void) drawViewBackgroundInRect:(NSRect)rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    NSRect bounds = [self bounds];

    CGContextClearRect(context, bounds);

    NSColor *color1 = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.25];
    NSColor *color2 = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.0];

    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:color1 endingColor:color2];
    
    [gradient drawInRect:bounds angle:-90];
    
    [[NSColor colorWithCalibratedWhite:0.5 alpha:0.25] set];
    
    CGRect strokeFrame = CGRectInset(bounds, 0.5, 0.5);
    
    CGContextSetLineWidth(context, 1);

    [[NSColor colorWithWhite:0.3 alpha:1.0] set];
    CGContextStrokeRect(context, strokeFrame);
}

@end
