//
//  ShroudView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "ShroudView.h"

@implementation ShroudView

- (BOOL) isFlipped
{
    return NO;
}

- (void) mouseUp:(NSEvent *)theEvent
{
    [_delegate shroudView:self clickedWithEvent:theEvent];
}


- (void) setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [[self layer] setCornerRadius:cornerRadius];
    }
}


@end
