//
//  ShroudView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "OverlayBaseView.h"

@implementation OverlayBaseView

- (instancetype) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setLayer:[CALayer layer]];
    }

    return self;
}


- (BOOL) isFlipped
{
    return NO;
}


- (void) mouseUp:(NSEvent *)theEvent
{
    [_delegate overlayBaseView:self clickedWithEvent:theEvent];
}


- (void) setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [[self layer] setCornerRadius:cornerRadius];
    }
}


@end
