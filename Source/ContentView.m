//
//  ShroudView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "ContentView.h"

@implementation ContentView

- (BOOL) isFlipped
{
    return NO;
}

- (void) mouseUp:(NSEvent *)theEvent
{
    [_delegate contentView:self clickedWithEvent:theEvent];
}


- (void) setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [[self layer] setCornerRadius:cornerRadius];
    }
}


@end
