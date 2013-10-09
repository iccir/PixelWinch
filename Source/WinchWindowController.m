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
    NSWindow *_transitionWindow;
    NSWindow *_shroudWindow;
    CGImageRef _transitionImage;
}
//
//- (id)initWithWindow:(NSWindow *)window;
//{
//    if ((self = [super initWithWindow:window])) {
//        _canvasController = [[CanvasController alloc] init];
//        _toolController   = [[ToolController   alloc] init];
//
//        [_toolController addObserver:self forKeyPath:@"selectedTool" options:0 context:nil];
//    }
//
//    return self;
//}

- (NSString *) windowNibName
{
    return @"WinchWindow";
}

- (void) keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar   c          = [characters length] ? [characters characterAtIndex:0] : 0;
    
    BOOL handled = NO;
    
    if (([theEvent modifierFlags] & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask)) == 0) {
        if (c == 'z') {
            [_toolController selectToolWithType:ToolTypeZoom];
            handled = YES;

        } else if (c == 'h') {
            [_toolController selectToolWithType:ToolTypeHand];
            handled = YES;
        
        } else if (c == 'm') {
            [_toolController selectToolWithType:ToolTypeMarquee];
            handled = YES;
        
        } else if (c == 'v') {
            [_toolController selectToolWithType:ToolTypeMove];
            handled = YES;

        } else if (c == 'r') {
            [_toolController selectToolWithType:ToolTypeRectangle];
            handled = YES;

        } else if (c == 'g') {
            [_toolController selectToolWithType:ToolTypeGrapple];
            handled = YES;

        } else if (c == NSDeleteCharacter || c == NSBackspaceCharacter) {
            handled = [_canvasController deleteSelectedObjects];
        }
    }
    

    if (!handled) {
        [super keyDown:theEvent];
    }
}


- (void) flagsChanged:(NSEvent *)theEvent
{
    [_canvasController flagsChanged:theEvent];
    [super flagsChanged:theEvent];
}


- (void) _setupViewControllers
{
    _canvasController = [[CanvasController alloc] init];
    _toolController   = [[ToolController alloc] init];
    
    NSView *canvasView = [_canvasController view];
    NSView *toolView   = [_toolController view];

    [_canvasContainer addSubview:canvasView];
    [canvasView setFrame:[_canvasContainer bounds]];
    [canvasView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    
    [_toolContainer addSubview:toolView];
    [toolView setFrame:[_toolContainer bounds]];
    [toolView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];

    [_canvasController setZoomTool:[_toolController zoomTool]];

    [_canvasController addObserver:self forKeyPath:@"selectedObject" options:0 context:0];
    [_toolController   addObserver:self forKeyPath:@"selectedTool"   options:0 context:0];
}


- (void) awakeFromNib
{
    NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;

    NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, 640, 400) styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];

    [_contentView setWantsLayer:YES];
    [_contentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];

    [window setContentView:_contentView];
    [window setHasShadow:NO];
    [window setBackgroundColor:[NSColor colorWithCalibratedWhite:0 alpha:0.8]];
    [window setOpaque:NO];

    [window setDelegate:self];
    
    [self setWindow:window];

    [self _setupViewControllers];
}


- (NSScreen *) screenWithMousePointer
{
    NSScreen *result = nil;

    NSPoint mouseLocation = [NSEvent mouseLocation];

    for (NSScreen *screen in [NSScreen screens]) {
        if (NSMouseInRect(mouseLocation, [screen frame], NO)) {
            result = screen;
            break;
        }
    }

    if (!result) {
        result = [NSScreen mainScreen];
    }

    return result;
}


- (void) presentWithImage:(CGImageRef)image screenRect:(CGRect)screenRect
{
    CGFloat screenZeroHeight = [[NSScreen mainScreen] frame].size.height;
    screenRect.origin.y = screenZeroHeight - CGRectGetMaxY(screenRect);

    NSScreen *mouseScreen = [self screenWithMousePointer];

    NSWindow *window = [[NSWindow alloc] initWithContentRect:[mouseScreen frame] styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    [window setOpaque:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setLevel:kCGDraggingWindowLevelKey];

    NSView *contentView = [window contentView];
    
    CGRect frame = [contentView convertRect:screenRect fromView:nil];
    
    NSView *imageView = [[NSView alloc] initWithFrame:frame];
    [imageView setWantsLayer:YES];
    [[imageView layer] setContents:(__bridge id)image];
    [[imageView layer] setMagnificationFilter:kCAFilterNearest];
    
    [contentView addSubview:imageView];

    [NSApp activateIgnoringOtherApps:YES];
    [window orderFront:self];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:5.35];
        [[imageView animator] setFrame:[contentView bounds]];
    } completionHandler:^{
        [_transitionWindow orderOut:self];
    }];
    
    
    CGImageRelease(_transitionImage);
    _transitionImage  = CGImageRetain(image);

    _transitionWindow = window;
    
    [self showWindow:self];
}



- (void) showWindow:(id)sender
{
    NSScreen *mouseScreen = [self screenWithMousePointer];

    _shroudWindow = [[NSWindow alloc] initWithContentRect:[mouseScreen frame] styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    [_shroudWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:0 alpha:1.0]];
    [_shroudWindow setOpaque:NO];
    [_shroudWindow setAlphaValue:0.25];
    [_shroudWindow orderFront:self];
    [_shroudWindow setLevel:NSScreenSaverWindowLevel];

    [[self window] center];
    [super showWindow:self];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _toolController) {
        if ([keyPath isEqualToString:@"selectedTool"]) {
            [_canvasController setSelectedTool:[_toolController selectedTool]];
        }

    } else if (object == _canvasController) {
        if ([keyPath isEqualToString:@"selectedObject"]) {
            [_toolController setSelectedObject:[_canvasController selectedObject]];
        }
    }
}

@end
