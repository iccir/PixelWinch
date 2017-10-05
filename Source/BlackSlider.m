//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "BlackSlider.h"

@implementation BlackSlider


@end

@implementation BlackSliderCell

- (void)drawKnob:(NSRect)knobRect
{
    NSImage *image;

    if ([self isHighlighted]) {
        image = [NSImage imageNamed:@"SliderKnobHighlighted"];
    } else {
        image = [NSImage imageNamed:@"SliderKnobNormal"];
    }

    DrawImageAtPoint(image, knobRect.origin);
}


- (void) drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
    NSImage *well = [NSImage imageNamed:@"SliderWell"];
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
