//
//  Window.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-07.
//
//

#import "CanvasWindow.h"

@implementation CanvasWindow {
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
    NSRect result = [super constrainFrameRect:frameRect toScreen:screen];
    result.origin = [screen frame].origin;
    return result;
}


@end
