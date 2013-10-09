//
//  BlackButtonCell.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "BlackButtonCell.h"

@implementation BlackButtonCell {
    NSButtonType _type;
}


- (void) setButtonType:(NSButtonType)type
{
    _type = type;
    [super setButtonType:type];
}

- (NSRect) drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView
{
    NSMutableAttributedString *as = [title mutableCopy];
    NSRange entireRange = NSMakeRange(0, [as length]);
    
    [as setAttributes:@{ NSForegroundColorAttributeName: [NSColor colorWithWhite:1.0 alpha:1.0] } range:entireRange];
    
    __block NSRect result;
    WithWhiteOnBlackTextMode(^{
        result =      [super drawTitle:as withFrame:frame inView:controlView];
    });

    return result;
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSButton *)controlView
{
    if (_type == NSRadioButton) {
        [[NSColor redColor] set];
        NSRectFill(cellFrame);
    }

    [super drawWithFrame:cellFrame inView:controlView];
}


@end
