//
//  Window.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-07.
//
//

#import "Window.h"

@implementation Window {
    BOOL _canBecomeKeyWindow;
    BOOL _canBecomeMainWindow;
    BOOL _useCanBecomeKeyWindow;
    BOOL _useCanBecomeMainWindow;
}


- (void) cancelOperation:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(window:cancelOperation:)]) {
        BOOL result = [[self delegate] window:self cancelOperation:sender];
        if (result) return;
    }

    [super cancelOperation:sender];
}


- (void) setDelegate:(id<WindowDelegate>)anObject
{
    [super setDelegate:(id)anObject];
}


- (id<WindowDelegate>) delegate
{
    return (id<WindowDelegate>)[super delegate];
}


- (BOOL) canBecomeKeyWindow
{
    if (_useCanBecomeKeyWindow) {
        return _canBecomeKeyWindow;
    } else {
        return [super canBecomeKeyWindow];
    }
}


- (BOOL) canBecomeMainWindow
{
    if (_useCanBecomeMainWindow) {
        return _canBecomeMainWindow;
    } else {
        return [super canBecomeMainWindow];
    }
}


- (void) setCanBecomeKeyWindow:(BOOL)canBecomeKeyWindow
{
    _canBecomeKeyWindow = canBecomeKeyWindow;
    _useCanBecomeKeyWindow = YES;
}


- (void) setCanBecomeMainWindow:(BOOL)canBecomeMainWindow
{
    _canBecomeMainWindow = canBecomeMainWindow;
    _useCanBecomeMainWindow = YES;
}


@end
