//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "CursorInfo.h"

@interface CursorInfoView : NSView
@property (nonatomic, strong) NSString *text;
@end


static void sUpdateWindow(NSWindow *window)
{
    NSPoint point = [NSEvent mouseLocation];
    point.x += 10;
    point.y -= 30;
    [window setFrameOrigin:point];
}


static CGEventRef sEventTapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *rawUserInfo)
{
    NSWindow *window = (__bridge NSWindow *)rawUserInfo;
    sUpdateWindow(window);
    return event;
}


@implementation CursorInfoView {
    
}

- (BOOL) isFlipped
{
    return YES;
}


- (void) drawRect:(NSRect)dirtyRect
{
    NSFont *font = [NSFont userFontOfSize:13];
    
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    [ps setLineSpacing:0];
    [ps setMaximumLineHeight:13];
    [ps setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: font,
        NSParagraphStyleAttributeName: ps
    };

    NSRect rect = [_text boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
    NSSize size = rect.size;

    [[NSColor colorWithCalibratedWhite:0 alpha:0.75] set];
    
    CGSize padding = NSMakeSize(8, 2);
    
    size.width  = ceil(size.width)  + (2 * padding.width);
    size.height = ceil(size.height) + (2 * padding.height);

    CGFloat radius = size.width < size.height ? size.width : size.height;
    radius /= 2;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height) xRadius:radius yRadius:radius];
    [path fill];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:2];
    [shadow setShadowOffset:NSMakeSize(0, 0)];
    [shadow set];
    
    [_text drawAtPoint:NSMakePoint(padding.width, padding.height) withAttributes:attributes];
}


- (void) setText:(NSString *)text
{
    if (_text != text) {
        _text = text;
        [self setNeedsDisplay:YES];
    }
}


- (BOOL) isOpaque
{
    return NO;
}


@end


@implementation CursorInfo {
    NSWindow *_window;
    CursorInfoView *_view;

    NSString *_text;
    NSMutableDictionary *_textMap;

    CFMachPortRef _eventTap;
    CFRunLoopSourceRef _eventTapRunLoopSource;
    
    BOOL _orderedIn;
}


+ (instancetype) sharedInstance
{
    static CursorInfo *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[CursorInfo alloc] init];
    });
    
    return sSharedInstance;
}


- (void) dealloc
{
    if (_eventTap) {
        CGEventTapEnable(_eventTap, false);
        CFRelease(_eventTap);
        _eventTap = NULL;
    }
}


- (void) _makeWindow
{
    if (_window) return;

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 256, 32) styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    
    [_window setBackgroundColor:[NSColor clearColor]];
    [_window setOpaque:NO];
    [_window setLevel:kCGCursorWindowLevel];
    [_window setIgnoresMouseEvents:YES];
    
    [[_window contentView] setLayer:[CALayer layer]];
    [[_window contentView] setWantsLayer:YES];

    _view = [[CursorInfoView alloc] initWithFrame:[[_window contentView] bounds]];
    [_view setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [[_window contentView] addSubview:_view];
    [_view setText:_text];
}


- (void) _makeTap
{
    if (_eventTap) return;

    CGEventMask mask = CGEventMaskBit(kCGEventMouseMoved)  |
                       CGEventMaskBit(kCGEventLeftMouseDragged)    |
                       CGEventMaskBit(kCGEventRightMouseDragged);

    _eventTap = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly, mask, sEventTapCallBack, (__bridge void *)_window);
    _eventTapRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(), _eventTapRunLoopSource, (__bridge CFStringRef)NSEventTrackingRunLoopMode);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _eventTapRunLoopSource, kCFRunLoopCommonModes);

    CGEventTapEnable(_eventTap, true);
}


- (void) _updateWindow
{
    if ([_text length] && _enabled) {
        [_view setText:_text];

        if (!_window)   [self _makeWindow];
        if (!_eventTap) [self _makeTap];

        sUpdateWindow(_window);
        [_window orderFront:self];

        CGEventTapEnable(_eventTap, true);

    } else {
        [_window orderOut:self];
        if (_eventTap) CGEventTapEnable(_eventTap, false);
    }
}


- (void) _setText:(NSString *)text
{
    if (!text || ![_text isEqualToString:text]) {
        _text = text;
        [self _updateWindow];
    }
}


- (void) setText:(NSString *)text forKey:(NSString *)key
{
    if (!_textMap) _textMap = [NSMutableDictionary dictionary];

    if ([text length]) {
        [_textMap setObject:text forKey:key];
    } else {
        [_textMap removeObjectForKey:key];
    }

    if ([_textMap count]) {
        NSArray *sortedKeys = [[_textMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
        [self _setText:[_textMap objectForKey:[sortedKeys firstObject]]];
    
    } else {
        [self _setText:nil];
    }
}


- (NSString *) textForKey:(NSString *)key
{
    return [_textMap objectForKey:key];
}


- (void) setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        [self _updateWindow];
    }
}

@end
