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

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _type = [[self valueForKey:@"buttonType"] integerValue];
    }
    
    return self;
}

- (NSRect) drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView
{
    NSMutableAttributedString *as = [title mutableCopy];
    NSRange entireRange = NSMakeRange(0, [as length]);
    
    [as setAttributes:@{ NSForegroundColorAttributeName: GetRGBColor(0xFFFFFF, 1.0) } range:entireRange];
    
    __block NSRect result;
    WithWhiteOnBlackTextMode(^{
        result =      [super drawTitle:as withFrame:frame inView:controlView];
    });

    return result;
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSButton *)controlView
{
    if (_type == NSRadioButton) {
        NSImage *image = [NSImage imageNamed:@"radio_normal"];

        if ([self state] == NSOnState) {
            image = [NSImage imageNamed:@"radio_selected"];
        } else if ([self isHighlighted]) {
            image = [NSImage imageNamed:@"radio_highlighted"];
        }
        
        DrawImageAtPoint(image, CGPointMake(cellFrame.origin.x + 2, cellFrame.origin.y + 1));
    }

//    [super drawWithFrame:cellFrame inView:controlView];


    NSDictionary *attributes = @{
        NSFontAttributeName: [self font]
    };
    
    CGRect textFrame = cellFrame;
    textFrame.origin.x += 20;
    textFrame.size.width -= 20;
    textFrame.origin.y -= 1.0;

    NSAttributedString *as = [[NSAttributedString alloc] initWithString:[self title] attributes:attributes];
    [self drawTitle:as withFrame:textFrame inView:controlView];

}


@end
