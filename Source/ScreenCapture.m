//
//  CaptureManager.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-27.
//
//

#import "ScreenCapture.h"

@implementation ScreenCapture {
    NSWindow *_infoWindow;
    NSTextField *_topLabel;
    NSTextField *_bottomLabel;
}

- (void) _setupCaptureWindow
{
    CGRect contentRect = CGRectMake(0, 0, 64, 64);
    

    NSWindow *window = [[NSWindow alloc] initWithContentRect:contentRect styleMask:0 backing:NSBackingStoreBuffered defer:NO];

    [window setOpaque:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setSharingType:NSWindowSharingNone];
    [window setLevel:(kCGCursorWindowLevel - 1)];

    NSTextField *topLabel = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 64, 32)];
    [topLabel setBezeled:NO];
    [topLabel setBordered:NO];
    [topLabel setDrawsBackground:NO];
    [topLabel setFont:[NSFont systemFontOfSize:11]];
    [topLabel setEditable:NO];
 
       [topLabel setTextColor:[NSColor blackColor]];

    [[window contentView] addSubview:topLabel];
    _topLabel = topLabel;

    NSTextField *bottomLabel = [[NSTextField alloc] initWithFrame:CGRectMake(0, 32, 64, 32)];
    [bottomLabel setBezeled:NO];
    [bottomLabel setBordered:NO];
    [bottomLabel setDrawsBackground:NO];
    [bottomLabel setFont:[NSFont systemFontOfSize:11]];
    [bottomLabel setTextColor:[NSColor blackColor]];
    [bottomLabel setEditable:NO];

    [[window contentView] addSubview:bottomLabel];
    _bottomLabel = bottomLabel;

    [window makeKeyAndOrderFront:self];

    _infoWindow = window;
}

- (void) startCaptureWithMode:(ScreenCaptureMode)mode
{
    [self _setupCaptureWindow];
}

- (void) mouseLocationDidChange:(CGPoint)point
{
    [_infoWindow setFrameTopLeftPoint:point];

    [_topLabel setStringValue:[NSString stringWithFormat:@"X: %ld", (long)point.x]];
    [_bottomLabel setStringValue:[NSString stringWithFormat:@"Y: %ld", (long)point.y]];
    
    [_infoWindow orderFront:self];
}

- (void) cancel
{
    
}


@end
