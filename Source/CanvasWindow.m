//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "CanvasWindow.h"


@implementation CanvasWindow {
}

- (void) performClose:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(window:performClose:)]) {
        BOOL result = [[self delegate] window:self performClose:sender];
        if (result) return;
    }

    [super performClose:sender];
}


- (void) cancelOperation:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(window:cancelOperation:)]) {
        BOOL result = [[self delegate] window:self cancelOperation:sender];
        if (result) return;
    }

    [super cancelOperation:sender];
}

- (void) setDelegate:(id<CanvasWindowDelegate>)anObject
{
    [super setDelegate:(id)anObject];
}


- (id<CanvasWindowDelegate>) delegate
{
    return (id<CanvasWindowDelegate>)[super delegate];
}


- (BOOL) canBecomeKeyWindow
{
    return YES;
}


- (BOOL) canBecomeMainWindow
{
    return YES;
}


- (NSRect) constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
    return frameRect;
//    NSLog(@"Constrain to %@", [screen winch_name]);
//
//    NSRect result = [super constrainFrameRect:frameRect toScreen:screen];
//    if (screen) result.origin = [screen frame].origin;
//    return result;
}


@end
