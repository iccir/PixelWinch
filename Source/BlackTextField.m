//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "BlackTextField.h"
#import "BlackTextView.h"

@interface NSTextField () <NSTextViewDelegate>
@end


@implementation BlackTextField


- (void) awakeFromNib
{
   [self setBackgroundColor:[NSColor blackColor]];
   [self setBezeled:NO];
}


- (void) drawRect:(NSRect)rect
{
    WithWhiteOnBlackTextMode(^{
        [super drawRect:rect];
    });
}

@end


@implementation BlackTextFieldCell

- (NSTextView *) fieldEditorForView:(NSView *)aControlView
{
    if ([aControlView isKindOfClass:[BlackTextField class]]) {
        BlackTextView *editor = [[BlackTextView alloc] initWithFrame:[aControlView bounds]];
        [editor setFieldEditor:YES];
        return editor;
    }
    
    return nil;
}


- (NSText *) setUpFieldEditorAttributes:(NSText *)editor
{
    [super setUpFieldEditorAttributes:editor];
    
    if ([editor isKindOfClass:[NSTextView class]]) {
        NSTextView *textView = (NSTextView *)editor;
        [textView setInsertionPointColor:[NSColor whiteColor]];

        [textView setTextContainerInset:NSMakeSize(2, 2)];
        [textView setBackgroundColor:[NSColor clearColor]];
        
        [textView setFocusRingType:NSFocusRingTypeExterior];

        [textView setSelectedTextAttributes:@{
            NSBackgroundColorAttributeName: [NSColor colorWithWhite:0.5 alpha:1.0],
        }];

    }

    return editor;
}


- (void) drawWithFrame:(NSRect)cellFrame inView:(BlackTextField *)controlView
{
    if ([controlView drawsBackground]) {
        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

        CGContextClearRect(context, cellFrame);

        NSColor *color1 = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.25];
        NSColor *color2 = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.0];

        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:color1 endingColor:color2];
        
        [gradient drawInRect:cellFrame angle:-90];
        
        [[NSColor colorWithCalibratedWhite:0.5 alpha:0.25] set];
        
        CGRect strokeFrame = CGRectInset(cellFrame, 0.5, 0.5);
        
        CGContextSetLineWidth(context, 1);
        CGContextStrokeRect(context, strokeFrame);
        
        cellFrame = CGRectInset(cellFrame, 2, 2);
    }

    [self drawInteriorWithFrame:cellFrame inView:controlView];
}


- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(BlackTextField *)controlView
{
    NSColor *oldColor = [self backgroundColor];
    [self setBackgroundColor:[NSColor clearColor]];

    WithWhiteOnBlackTextMode(^{
        [super drawInteriorWithFrame:cellFrame inView:controlView];
    });
    
    [self setBackgroundColor:oldColor];
}


- (NSColor *) textColor
{
    return GetRGBColor(0xd8d8d8, 1.0);
}


@end
