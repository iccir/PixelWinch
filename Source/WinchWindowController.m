//
//  MasterController.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import "WinchWindowController.h"

#import "CanvasController.h"
#import "ToolController.h"

@interface WinchWindowController () <NSWindowDelegate>
@end


@implementation WinchWindowController {
    CanvasController *_canvasController;
    ToolController   *_toolController;
}

- (id)initWithWindow:(NSWindow *)window;
{
    if ((self = [super initWithWindow:window])) {
        _canvasController = [[CanvasController alloc] init];
        _toolController   = [[ToolController   alloc] init];

        [_toolController addObserver:self forKeyPath:@"selectedTool" options:0 context:nil];
    }

    return self;
}

- (void) keyDown:(NSEvent *)theEvent
{
    if (([theEvent modifierFlags] & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask)) == 0) {
        if ([[theEvent characters] isEqualToString:@"z"]) {
            [_toolController setSelectedTool:ToolTypeZoom];
        
        } else if ([[theEvent characters] isEqualToString:@"m"]) {
            [_toolController setSelectedTool:ToolTypeMarquee];
        
        } else if ([[theEvent characters] isEqualToString:@"v"]) {
            [_toolController setSelectedTool:ToolTypeMove];
        }
    }
    
    
    [super keyDown:theEvent];
}


- (void) loadWindow
{
    NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;

    NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, 640, 320) styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
    [[window contentView] setWantsLayer:YES];
    [window setDelegate:self];
    
    [[_canvasController view] setFrameOrigin:NSMakePoint(130, 0)];
    
    [[window contentView] addSubview:[_canvasController view]];
    [[_canvasController view] setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    
    [[window contentView] addSubview:[_toolController view]];

    [self setWindow:window];
}


- (NSWindow *) window
{
    NSWindow *window = [super window];
    if (!window) [self loadWindow];
    return window;
}


- (void) showWindow:(id)sender
{
    [self window];
    [super showWindow:self];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _toolController) {
        if ([keyPath isEqualToString:@"selectedTool"]) {
            [_canvasController setSelectedTool:[_toolController selectedTool]];
        }
    }
}

@end
