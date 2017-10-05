//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "TutorialWindowController.h"

@implementation TutorialWindowController {
    NSStatusItem *_statusItem;
    NSWindow *_window;
    
    NSRect _startFrame;
    NSRect _endFrame;
}


- (CGRect) _screenRectOfStatusItem:(NSStatusItem *)statusItem
{
    NSView *oldView = [statusItem view];
    CGRect result = CGRectZero;

    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
    [statusItem setView:view];

    if ([view window]) {
        NSRect statusItemRect = [view convertRect:[view bounds] toView:nil];
        result = [[view window] convertRectToScreen:statusItemRect];
    }

    [statusItem setView:oldView];

    return result;
}


- (void) _calculateStartAndEndFrame
{
    NSImage *image = [NSImage imageNamed:@"TutorialArrow"];
    NSSize imageSize = [image size];
    
    NSRect imageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);

    NSRect screenRect = [self _screenRectOfStatusItem:_statusItem];
    screenRect.origin.y -= ((imageRect.size.height + screenRect.size.height) - 8);

    screenRect.origin.x += round(screenRect.size.width / 2);
    screenRect.origin.x -= round(imageRect.size.width  / 2);

    screenRect.size = imageSize;

    _endFrame = screenRect;

    screenRect.origin.y -= 128.0;
    _startFrame = screenRect;
}


- (void) orderInWithStatusItem:(NSStatusItem *)statusItem
{
    _statusItem = statusItem;
    
    NSImage *image = [NSImage imageNamed:@"TutorialArrow"];
    NSSize imageSize = [image size];
    
    NSRect imageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
    
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:imageRect];
    [imageView setImage:image];
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:imageRect styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    
    [window setBackgroundColor:[NSColor clearColor]];
    [window setOpaque:NO];
    [window setLevel:kCGCursorWindowLevel - 1];
    [window setIgnoresMouseEvents:YES];
    
    [[window contentView] addSubview:imageView];

    [self _calculateStartAndEndFrame];

    [window setAlphaValue:0];
    [window setFrameOrigin:_startFrame.origin];
    [window makeKeyAndOrderFront:self];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:1.0];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

        [[window animator] setFrame:_endFrame display:NO];
        [[window animator] setAlphaValue:1];
    } completionHandler:nil];

    _window = window;
}




- (void) orderOut
{
    [_window orderOut:self];
    _window = nil;
}


@end
