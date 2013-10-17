//
//  BlackSlider.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "BlackSlider.h"

@implementation BlackSlider


@end

@implementation BlackSliderCell

- (void)drawKnob:(NSRect)knobRect
{
    NSImage *image;

    if ([self isHighlighted]) {
        image = [NSImage imageNamed:@"knob_highlighted"];
    } else {
        image = [NSImage imageNamed:@"knob_normal"];
    }

    DrawImageAtPoint(image, knobRect.origin);
}


- (void) drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
    NSImage *well = [NSImage imageNamed:@"slider_well"];
    aRect = CGRectInset(aRect, -1, -1);
    
    DrawThreePart(well, aRect, 5, 5);
}


- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSInteger numberOfTickMarks = [self numberOfTickMarks];
    [self setNumberOfTickMarks:0];
   
    [super drawWithFrame:cellFrame inView:controlView];
    
    [self setNumberOfTickMarks:numberOfTickMarks];
}


@end