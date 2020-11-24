//
//  CustomSlider.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2019-10-22.
//

#import "CustomSlider.h"

@implementation CustomSliderCell

- (void) drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
    NSRect  trackRect = CGRectInset([self trackRect], 1.0, 0.0);
    CGFloat knobMidX  = round(CGRectGetMidX([self knobRectFlipped:flipped]));

    trackRect.origin.y = (trackRect.size.height - 2) / 2;
    trackRect.size.height = 2;

    NSRect onRect, offRect;
    CGRectDivide(trackRect, &onRect, &offRect, knobMidX - trackRect.origin.x, CGRectMinXEdge);

    if (onRect.size.width > 0) {
        [[NSColor colorNamed:@"SliderActiveTrack"] set];
        [[NSBezierPath bezierPathWithRoundedRect:onRect xRadius:1 yRadius:1] fill];
    }

    if (offRect.size.width > 0) {
        [[NSColor colorNamed:@"SliderInactiveTrack"] set];
        [[NSBezierPath bezierPathWithRoundedRect:offRect xRadius:1 yRadius:1] fill];
    }
}

@end

