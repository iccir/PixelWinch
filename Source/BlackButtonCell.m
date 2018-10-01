//  (c) 2013-2018, Ricci Adams.  All rights reserved.


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

- (void) _drawImageForNormalButtonWithFrame:(NSRect)cellFrame
{
    NSImage *image = [self image];

    NSRectFillListUsingOperation(&cellFrame, 1, NSCompositingOperationClear);

    NSRect shadowFrame = cellFrame;
    shadowFrame.size.height -= 1.0;

    NSSize imageSize = [image size];
    NSRect imageRect = { cellFrame.origin, imageSize };

    imageRect.origin.y = cellFrame.origin.y;
    imageRect.origin.x += round((cellFrame.size.width  - imageSize.width)  / 2);
    imageRect.origin.y += round(((cellFrame.size.height - 1) - imageSize.height) / 2);

    [image drawInRect:imageRect];
}


- (NSRect) drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView
{
    NSMutableAttributedString *as = [title mutableCopy];
    NSRange entireRange = NSMakeRange(0, [as length]);
    
    if (entireRange.length) {
        [as setAttributes:@{
            NSForegroundColorAttributeName: GetRGBColor(0xd8d8d8, 1.0),
            NSFontAttributeName: [self font]
        } range:entireRange];
    }

    __block NSRect result;
    WithWhiteOnBlackTextMode(^{
        result = [super drawTitle:as withFrame:frame inView:controlView];
    });

    return result;
}


- (void) drawWithFrame:(NSRect)cellFrame inView:(NSButton *)controlView
{
    if (_type == NSRadioButton) {
        NSImage *image = [NSImage imageNamed:@"RadioNormal"];

        if ([self state] == NSOnState) {
            image = [NSImage imageNamed:@"RadioSelected"];
        } else if ([self isHighlighted]) {
            image = [NSImage imageNamed:@"RadioHighlighted"];
        }
        
        DrawImageAtPoint(image, CGPointMake(cellFrame.origin.x + 2, cellFrame.origin.y + 2));

    } else if (_type == NSMomentaryLightButton || _type == NSMomentaryPushInButton) {
        [self _drawImageForNormalButtonWithFrame:cellFrame];
    }

    CGRect textFrame = cellFrame;
    textFrame.origin.x += 20;
    textFrame.size.width -= 20;
    textFrame.origin.y -= 0.0;

    NSString *title = [self title];
    if (title && [title length]) {
        NSDictionary *attributes = @{
            NSFontAttributeName: [self font]
        };

        NSAttributedString *as = [[NSAttributedString alloc] initWithString:title attributes:attributes];
        [self drawTitle:as withFrame:textFrame inView:controlView];
    }
}


@end
