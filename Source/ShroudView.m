//
//  ShroudView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "ShroudView.h"

@implementation ShroudView {
    NSColor *_backgroundColor;
}

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setWantsLayer:YES];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
    }

    return self;
}


- (BOOL) wantsUpdateLayer
{
    return YES;
}


- (void) updateLayer{ }


- (void) mouseUp:(NSEvent *)theEvent
{
    [_delegate shroudView:self clickedWithEvent:theEvent];
}

- (void) setBackgroundColor:(NSColor *)backgroundColor
{
    @synchronized(self) {
        if (_backgroundColor != backgroundColor) {
            _backgroundColor = backgroundColor;
            [[self layer] setBackgroundColor:[backgroundColor CGColor]];
        }
    }
}


- (NSColor *) backgroundColor
{
    @synchronized(self) {
        return _backgroundColor;
    }
}


- (void) setCornerRadius:(CGFloat)cornerRadius
{
    @synchronized(self) {
        [[self layer] setCornerRadius:cornerRadius];
    }
}

- (CGFloat) cornerRadius
{
    @synchronized(self) {
        return [[self layer] cornerRadius];
    }
}


@end
