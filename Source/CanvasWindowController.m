//
//  DocumentController.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "CanvasWindowController.h"

#import "BlackSegmentedControl.h"

#import "Library.h"
#import "LibraryItem.h"
#import "Screenshot.h"

#import "BlackScroller.h"

#import "ShadowView.h"
#import "CanvasView.h"
#import "RulerView.h"
#import "CenteringClipView.h"
#import "WindowResizerKnob.h"
#import "GratuitousDelayButton.h"

#import "MagnificationManager.h"

#import "Toolbox.h"
#import "Tool.h"
#import "MoveTool.h"
#import "LineTool.h"
#import "HandTool.h"
#import "MarqueeTool.h"
#import "RectangleTool.h"
#import "GrappleTool.h"
#import "ZoomTool.h"

#import "Canvas.h"
#import "Guide.h"
#import "Marquee.h"
#import "Line.h"
#import "Rectangle.h"

#import "GuideObjectView.h"
#import "LineObjectView.h"
#import "MarqueeObjectView.h"
#import "RectangleObjectView.h"
#import "ResizeKnobView.h"
#import "ContentView.h"
#import "CanvasWindow.h"

#import "CursorAdditions.h"


#if 0 && DEBUG
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif


typedef NS_ENUM(NSInteger, AnimationAction) {
    AnimationAction_DoOrderIn,
    
    AnimationAction_DoOrderOut,
    AnimationAction_RunOrderOutAnimation,
    AnimationAction_FinishOrderOutAnimation,

    AnimationAction_UpdateOverlayForScreen,
    
    AnimationAction_CleanupShield,

    AnimationAction_SetupTransitionImageView,
    AnimationAction_SetupShield,
    AnimationAction_SetupGratuitousButton,
        
    AnimationAction_RunFadeInOverlayAnimation,
    AnimationAction_FinishFadeInOverlayAnimation,
    AnimationAction_RunPopInOverlayAnimation,
    
    AnimationAction_RunFadeInShieldAnimation,
    AnimationAction_FinishFadeInShieldAnimation
};


// Use Dock's approach to anti-hacking: keep things in globals (ew!)
static CGRect       sTransitionImageGlobalRect = {0};
static CGImageRef   sTransitionImage           = NULL;
static BOOL         sShowDelayNextTime         = NO;


static inline void sGetPleaDuration(NSTimeInterval *outA, NSTimeInterval *outB)
{
    // The __arc_weak_lock global struct is actually "number of screenshots captured this session"
    // represented in postive and negative integers and doubles
    //
    NSInteger positive_i = __arc_weak_lock.count;
    NSInteger negative_i = __arc_weak_lock.s1;
    double    positive_f = __arc_weak_lock.s2;
    double    negative_f = __arc_weak_lock.s3;

    // Adding the positive and negative portions should always be 0.  If not, the struct has been manipulated
    NSInteger shouldBeZero_i = labs(positive_i + negative_i);
    double    shouldBeZero_f = fabs(round(positive_f + negative_f));

    // Bitshifting 0 should always be 0.  Messaging nil should never crash
    [(__bridge id)(void *)(       shouldBeZero_i  << 16) copy];
    [(__bridge id)(void *)(lround(shouldBeZero_f) << 24) copy];

    // duration = screenshots * 3
    NSTimeInterval a = (__arc_weak_lock.s1 + 1) * -4;
    NSTimeInterval b = (__arc_weak_lock.s2 - 1) *  4;

    // duration = MIN(duration, 8)
    a = MIN(a, ((       shouldBeZero_i  + 1) << 3));
    b = MIN(b, ((lround(shouldBeZero_f) + 1) << 3));

    // duration = MAX(duration, 0)
    a = MAX(a, shouldBeZero_i);
    b = MAX(b, shouldBeZero_i);
    
    *outA = 5;
    *outB = 5;
}


@interface CanvasWindowController () <
    NSToolbarDelegate,
    CanvasWindowDelegate,
    ContentViewDelegate,
    CanvasDelegate,
    CanvasViewDelegate,
    RulerViewDelegate,
    ToolOwner,
    WindowResizerKnobDelegate
>

@end


@implementation CanvasWindowController {
    NSWindow    *_canvasWindow;
    ContentView *_contentView;
    
    NSRect _contentViewFrameAtResizeStart;
    NSRect _contentViewMinFrameAtResizeStart;
    NSRect _contentViewMaxFrameAtResizeStart;

    Toolbox     *_toolbox;
    
    ShadowView  *_shadowView;
    ContentView *_shroudView;

    CGFloat      _liveMagnificationLevel;
    CGPoint      _liveMagnificationPoint;

    Canvas      *_canvas;
    ObjectEdge   _selectedEdge;
    
    LibraryItem  *_currentLibraryItem;

    NSMutableDictionary *_GUIDToViewMap;
    NSMutableDictionary *_GUIDToResizeKnobsMap;

    BOOL _windowIsOverlay;
}


+ (void) initialize
{
    [Line      class];
    [Guide     class];
    [Marquee   class];
    [Rectangle class];
}


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        _GUIDToViewMap = [NSMutableDictionary dictionary];

        _toolbox = [[Toolbox alloc] init];
        [self setPreferences:[Preferences sharedInstance]];

        for (Tool *tool in [_toolbox allTools]) {
            [tool setOwner:self];
        }

        [_toolbox addObserver:self forKeyPath:@"selectedTool" options:0 context:NULL];

        _library = [Library sharedInstance];
        
        _magnificationManager = [[MagnificationManager alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleApplicationDidResignActiveNotification:) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
    }
    
    return self;
}


- (void) dealloc
{
    [_toolbox removeObserver:self forKeyPath:@"selectedTool" context:NULL];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) flagsChanged:(NSEvent *)theEvent
{
    [_canvasView invalidateCursors];
    [[_toolbox selectedTool] flagsChangedWithEvent:theEvent];
    [super flagsChanged:theEvent];
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(toggleGuides:)) {
        NSString *title;
        BOOL isHidden = [_canvas isGroupNameHidden:[Guide groupName]];

        if (isHidden) {
            title = NSLocalizedString(@"Show Guides", nil);
        } else {
            title = NSLocalizedString(@"Hide Guides", nil);
        }
        
        [menuItem setTitle:title];
    }

    return YES;
}


- (void) keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar   c          = [characters length] ? [characters characterAtIndex:0] : 0;

    NSUInteger modifierFlags = [theEvent modifierFlags] & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask);

    BOOL isArrowKey = (c == NSUpArrowFunctionKey ||
                       c == NSDownArrowFunctionKey ||
                       c == NSLeftArrowFunctionKey ||
                       c == NSRightArrowFunctionKey);
    
    if (c == ' ') {
        if (![theEvent isARepeat]) {
            [_toolbox beginTemporaryHand];
        }

        return;
    }

    if (modifierFlags == 0) {
        NSArray *tools = [_toolbox allTools];

        for (Tool *tool in tools) {
            unichar key = [tool shortcutKey];

            if (key && (key == c)) {
                [_toolbox setSelectedToolName:[tool name]];
                return;
            }
        }
    
        if (c == NSDeleteCharacter || c == NSBackspaceCharacter) {
            if ([self _deleteSelectedObjects]) return;

        } else if (c == 'S') {
            if ([self _shrinkCurrentSelection]) return;

        } else if (c == 'E') {
            if ([self _expandCurrentSelection]) return;

        } else if (c >= '1' && c <= '3') {
            [[self preferences] setScaleMode:(c - '0')];
            return;

        } else if (isArrowKey) {
            if ([self _moveSelectionWithArrowKey:c delta:1]) {
                return;
            }
        }

    } else if (modifierFlags == NSCommandKeyMask) {
        if (c == NSDeleteCharacter || c == NSBackspaceCharacter) {
            [self deleteSelectedLibraryItem:nil];
            return;

        } else  if (c == ';') {
            [self toggleGuides:self];
            return;

        } else if (c == '-') {
            [_magnificationManager zoomOut];
            return;

        } else if (c == '=' || c == '+') {
            [_magnificationManager zoomIn];
            return;

        } else if (c == 'd') {
            if ([self _duplicateCurrentSelection]) return;
            return;

        } else if (c == 's') {
            [self exportItem:nil];
            return;

        } else if (c >= '1' && c <= '8') {
            NSInteger level = (c - '0');
            [_magnificationManager setMagnification:level];
            return;

        } else if (isArrowKey) {
            if ([self _selectEdgeWithArrowKey:c]) {
                return;
            }
        }

    } else if (modifierFlags == (NSCommandKeyMask | NSShiftKeyMask)) {
        if (c == '+') {
            [_magnificationManager zoomIn];
            return;

        } else if (c == '_') {
            [_magnificationManager zoomOut];
            return;

        } else if (c == '{') {
            [self loadPreviousLibraryItem:nil];
            return;

        } else if (c == '}') {
            [self loadNextLibraryItem:nil];
            return;
        }

    } else if (modifierFlags == NSShiftKeyMask) {
        if (isArrowKey) {
            if ([self _moveSelectionWithArrowKey:c delta:10]) {
                return;
            }
        }

    } else if (modifierFlags == (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask)) {
        if (c == 'r') {
            [self _debugResponderChain];
            return;

        } else if (c == 'k') {
            [self _debugKeyViewLoop];
            return;

        } else if (c == 'd') {
            [_canvas dumpDistanceMaps];
            return;

        } else if (c == 'a') {
            [[NSWorkspace sharedWorkspace] openFile:GetApplicationSupportDirectory()];
            return;
        }
    }

    [super keyDown:theEvent];
}


- (void) keyUp:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar   c          = [characters length] ? [characters characterAtIndex:0] : 0;

    if (c == ' ') {
        [_toolbox endTemporaryHand];
        return;
    }

    [super keyUp:theEvent];
}


- (void) beginGestureWithEvent:(NSEvent *)event
{
    CGPoint canvasPoint = [_canvasView canvasPointForEvent:event];
    CGSize  canvasSize  = [_canvas size];

    if (canvasPoint.x >= 0 &&
        canvasPoint.y >= 0 &&
        canvasPoint.x < canvasSize.width &&
        canvasPoint.y < canvasSize.height)
    {
        _liveMagnificationLevel = [_magnificationManager magnification];
        _liveMagnificationPoint = canvasPoint;
    } else {
        _liveMagnificationLevel = NAN;
    }
}


- (void) magnifyWithEvent:(NSEvent *)event
{
    if (!isnan(_liveMagnificationLevel)) {
        _liveMagnificationLevel *= ([event magnification] + 1);
        
        NSArray *levels = [_magnificationManager levelsForSlider];
        NSInteger index = [_magnificationManager indexInArray:levels forMagnification:_liveMagnificationLevel];
        
        CGFloat level = [[levels objectAtIndex:index] doubleValue];

        [_canvasView setMagnification:level pinnedAtCanvasPoint:_liveMagnificationPoint];
        [_magnificationManager setMagnification:level];
    }
}


- (void) awakeFromNib
{
    ProtectEntry();

    NSImage *arrowImage     = [NSImage imageNamed:@"ToolbarArrow"];
    NSImage *handImage      = [NSImage imageNamed:@"ToolbarHand"];
    NSImage *marqueeImage   = [NSImage imageNamed:@"ToolbarMarquee"];
    NSImage *rectangleImage = [NSImage imageNamed:@"ToolbarRectangle"];
    NSImage *lineImage      = [NSImage imageNamed:@"ToolbarLine"];
    NSImage *grappleImage   = [NSImage imageNamed:@"ToolbarGrapple"];
    NSImage *zoomImage      = [NSImage imageNamed:@"ToolbarZoom"];

    NSImage *scale1xImage   = [NSImage imageNamed:@"Toolbar1x"];
    NSImage *scale2xImage   = [NSImage imageNamed:@"Toolbar2x"];
    NSImage *scale3xImage   = [NSImage imageNamed:@"Toolbar3x"];

    [_toolPicker setTemplateImage:arrowImage     forSegment:0];
    [_toolPicker setTemplateImage:handImage      forSegment:1];
    [_toolPicker setTemplateImage:marqueeImage   forSegment:2];
    [_toolPicker setTemplateImage:rectangleImage forSegment:3];
    [_toolPicker setTemplateImage:lineImage      forSegment:4];
    [_toolPicker setTemplateImage:grappleImage   forSegment:5];
    [_toolPicker setTemplateImage:zoomImage      forSegment:6];

    [_scalePicker setTemplateImage:scale1xImage  forSegment:0];
    [_scalePicker setTemplateImage:scale2xImage  forSegment:1];
    [_scalePicker setTemplateImage:scale3xImage  forSegment:2];

    [_scalePicker setSelectedGradient:[[NSGradient alloc] initWithColors:@[
        GetRGBColor(0xffffa0, 1.0),
        GetRGBColor(0xffffe0, 1.0)
    ]] forSegment:1];

    [_scalePicker setSelectedGradient:[[NSGradient alloc] initWithColors:@[
        GetRGBColor(0xa0ffa0, 1.0),
        GetRGBColor(0xe0ffe0, 1.0)
    ]] forSegment:2];

    if ([[[Preferences sharedInstance] customScaleMultiplier] doubleValue]) {
        [_scalePicker setSegmentCount:4];

        [_scalePicker setSelectedGradient:[[NSGradient alloc] initWithColors:@[
            GetRGBColor(0xa0ffff, 1.0),
            GetRGBColor(0xe0ffff, 1.0)
        ]] forSegment:3];
        
        NSImage *scaleCxImage = [NSImage imageNamed:@"ToolbarCx"];
        [_scalePicker setTemplateImage:scaleCxImage forSegment:3];
        [_scalePicker setWidth:40 forSegment:3];

        NSRect pickerFrame = [_scalePicker frame];
        pickerFrame.size.width += 40;
        pickerFrame.origin.x -= 40;
        [_scalePicker setFrame:pickerFrame];
    }


    [_horizontalRuler setCanDrawConcurrently:YES];
    [_horizontalRuler setVertical:NO];
    
    [_verticalRuler setCanDrawConcurrently:YES];
    [_verticalRuler setVertical:YES];
    
    [_magnificationManager setHorizontalRuler:_horizontalRuler];
    [_magnificationManager setVerticalRuler:_verticalRuler];
    
    [[self resizerKnob] setDelegate:self];
    
    NSColor *darkColor = [NSColor colorWithWhite:0.1 alpha:1.0];

    [_canvasScrollView setBackgroundColor:darkColor];
    [[_canvasScrollView contentView] setBackgroundColor:darkColor];
    
    CenteringClipView *clipView = (CenteringClipView *)[_canvasScrollView contentView];
    [clipView setHorizontalRulerView:_horizontalRuler];
    [clipView setVerticalRulerView:_verticalRuler];

    [_canvasScrollView setScrollerKnobStyle:NSScrollerKnobStyleLight];
    [_canvasScrollView setScrollerStyle:NSScrollerStyleLegacy];

    [_libraryScrollView setBackgroundColor:darkColor];
    [[_libraryScrollView contentView] setBackgroundColor:darkColor];

    [_libraryScrollView setScrollerKnobStyle:NSScrollerKnobStyleLight];
    [_libraryScrollView setScrollerStyle:NSScrollerStyleOverlay];
    [[_libraryScrollView horizontalScroller] setControlSize:NSSmallControlSize];
    
    [_libraryCollectionView setBackgroundColors:@[ darkColor ]];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowOffset:NSMakeSize(0, 4)];
    [shadow setShadowBlurRadius:16];
    
    [self                   addObserver:self forKeyPath:@"librarySelectionIndexes" options:0 context:NULL];
    [self                   addObserver:self forKeyPath:@"selectedObject"          options:0 context:NULL];
    [_libraryCollectionView addObserver:self forKeyPath:@"isFirstResponder"        options:0 context:NULL];

    [self _updateWindowsForOverlayMode];

    [self _updateInspector];
    
    ProtectExit();
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _toolbox) {
        if ([keyPath isEqualToString:@"selectedTool"]) {
            [self _updateInspector];

            Tool *selectedTool = [_toolbox selectedTool];

            BOOL isMarqueeToolSelected = [selectedTool isEqual:[_toolbox marqueeTool]];
            
            [_canvas setGroupName:[Marquee groupName] hidden:!isMarqueeToolSelected];
            
            for (CanvasObject *selectedObject in [_canvas selectedObjects]) {
                if (![selectedTool canSelectCanvasObject:selectedObject]) {
                    [_canvas unselectObject:selectedObject];
                }
            }

            [_canvasView invalidateCursors];
        }

    } else if (object == self) {
        if ([keyPath isEqualToString:@"librarySelectionIndexes"]) {
            LibraryItem *item = [[_libraryArrayController selectedObjects] lastObject];

            if (item != _currentLibraryItem) {
                [self _updateCanvasWithLibraryItem:item];
            }

        } else if ([keyPath isEqualToString:@"selectedObject"]) {
            [self _updateInspector];
        }

    } else if (object == _libraryCollectionView) {
        if ([keyPath isEqualToString:@"isFirstResponder"]) {
            if ([_libraryCollectionView isFirstResponder]) {
                [_libraryCollectionView resignFirstResponder];
                [[self window] makeFirstResponder:[self window]];
            }
        }
    }
}


#pragma mark - Private Methods

- (void) _debugResponderChain
{
    NSLog(@"*** Start of responder chain ***");
    
    // Walk the responder chain, logging the next responder
    
    NSResponder *responder = [[self window] firstResponder];  // Starts with the receiver
    NSLog(@"First: %@", responder);
    while ( [responder nextResponder] ) {
        NSLog(@"%@", [responder nextResponder]);
        responder = [responder nextResponder]; // walk up the chain
    };
    NSLog(@"*** End of responder chain ***");
}


- (void) _debugKeyViewLoop
{
    NSLog(@"*** Start of key view loop ***");
    
    NSMutableSet *printedObjects = [NSMutableSet set];
    
    // Walk the responder chain, logging the next responder
    
    NSView *view = [[self window] initialFirstResponder];
    while ( [view nextKeyView] ) {
        NSLog(@"%@", [view nextKeyView]);
        view = [view nextKeyView]; // walk up the chain
        
        if ([printedObjects containsObject:view]) {
            break;
        } else {
            [printedObjects addObject:view];
        }
    };
    NSLog(@"*** End of key view loop ***");
}

- (void) _updateWindowsForOverlayMode
{
    BOOL usesOverlayWindow = [[Preferences sharedInstance] usesOverlayWindow];

    NSRect oldContentRect = CGRectMake(0, 0, 640, 400);

    if (IsLegacyOS()) {
        usesOverlayWindow = YES;
    }

    if (_canvasWindow) {
        oldContentRect = [_canvasWindow contentRectForFrameRect:[_canvasWindow frame]];
        [_canvasWindow setDelegate:nil];
        [_canvasWindow orderOut:nil];
        _canvasWindow = nil;
    }

    if (_contentView) {
        [_contentView setDelegate:nil];
        _contentView = nil;
    }

    if (_shroudView) {
        [_shroudView setDelegate:nil];
        _shroudView = nil;
    }

    NSUInteger canvasStyleMask = NSBorderlessWindowMask;
    
    if (!usesOverlayWindow) {
        canvasStyleMask |= NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSFullSizeContentViewWindowMask;
    }

    CanvasWindow *window = [[CanvasWindow alloc] initWithContentRect:oldContentRect styleMask:canvasStyleMask backing:NSBackingStoreBuffered defer:NO];

    XUIView *windowContentView = [[XUIView alloc] initWithFrame:[[window contentView] frame]];
    [windowContentView setFlipped:NO];

    [window setContentView:windowContentView];
    [window setRestorable:NO];
    [window setDelegate:self];
    [window setAutorecalculatesKeyViewLoop:YES];

    void (^buildTopView)(NSEdgeInsets, CGFloat) = ^(NSEdgeInsets outerPadding, CGFloat innerPadding) {
        NSView *toolPicker  = [self toolPicker];
        NSView *inspector   = [self inspectorContainer];
        NSView *scalePicker = [self scalePicker];
        
        NSRect toolFrame      = [toolPicker  frame];
        NSRect inspectorFrame = [inspector   frame];
        NSRect scaleFrame     = [scalePicker frame];

        NSSize neededSize = NSMakeSize(
            outerPadding.left + toolFrame.size.width  + innerPadding + inspectorFrame.size.width + innerPadding + scaleFrame.size.width + outerPadding.right,
            outerPadding.top  + toolFrame.size.height + outerPadding.bottom
        );
        
        CGPoint origin = CGPointMake(outerPadding.left, outerPadding.bottom);
        
        toolFrame.origin = origin;
        origin.x += toolFrame.size.width + innerPadding;

        inspectorFrame.origin = origin;
        origin.x += inspectorFrame.size.width + innerPadding;

        scaleFrame.origin = origin;

        NSRect frame    = { NSZeroPoint, neededSize };
        NSView *topView = [[NSView alloc] initWithFrame:frame];
        
        [toolPicker  setFrame:toolFrame];
        [inspector   setFrame:inspectorFrame];
        [scalePicker setFrame:scaleFrame];
        
        [topView addSubview:toolPicker];
        [topView addSubview:inspector];
        [topView addSubview:scalePicker];
        
        [topView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
        
        [self setTopView:topView];
    };
    
    if (usesOverlayWindow) {
        NSColor *darkColor = [_canvasScrollView backgroundColor];

        buildTopView(NSEdgeInsetsMake(9, 8, 6, 8), 8);

        [window setHasShadow:NO];
        [window setBackgroundColor:[NSColor clearColor]];
        [window setOpaque:NO];

        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow setShadowOffset:NSMakeSize(0, 4)];
        [shadow setShadowBlurRadius:16];

        _shroudView = [[ContentView alloc] initWithFrame:[windowContentView bounds]];
        [_shroudView setBackgroundColor:[NSColor colorWithCalibratedWhite:0 alpha:0.5]];
        [_shroudView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
        [_shroudView setDelegate:self];

        _shadowView = [[ShadowView alloc] initWithFrame:[windowContentView bounds]];
        [_shadowView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [_shadowView setBackgroundColor:darkColor];
        [_shadowView setCornerRadius:8];
        [_shadowView setShadow:shadow];

        _contentView = [[ContentView alloc] initWithFrame:[windowContentView bounds]];
        [_contentView setWantsLayer:YES];
        [_contentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [_contentView setBackgroundColor:darkColor];
        [_contentView setCornerRadius:8];
        [_contentView setDelegate:self];
        [_contentView setClipsToBounds:YES];
        
        [[self resizerKnob] setHidden:NO];
        
        NSView *topView    = [self topView];
        NSView *bottomView = [self bottomView];
        
        CGFloat topViewHeight = [topView bounds].size.height;
        
        NSRect containerBounds = [_contentView bounds];
        NSRect bottomFrame     = containerBounds;
        NSRect topFrame        = containerBounds;
        
        bottomFrame.size.height -= topViewHeight;
        topFrame.origin.y = NSMaxY(bottomFrame);
        topFrame.size.height = topViewHeight;

        [topView    setFrame:topFrame];
        [bottomView setFrame:bottomFrame];
        
        [_contentView addSubview:topView];
        [_contentView addSubview:bottomView];

        [windowContentView addSubview:_shroudView];
        [windowContentView addSubview:_shadowView];
        [windowContentView addSubview:_contentView];

        if (!IsInDebugger()) {
            [window setLevel:NSModalPanelWindowLevel-1];
        }
        
    } else {
        buildTopView(NSEdgeInsetsMake(9, 0, 6, 0), 8);

        [window setHasShadow:YES];

        [window setTitlebarAppearsTransparent:NO];
        [window setTitleVisibility:NSWindowTitleHidden];

        [window setBackgroundColor:[_canvasScrollView backgroundColor]];
        [window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        
        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"Toolbar"];

        [toolbar setDelegate:self];
        [toolbar setAllowsUserCustomization:NO];
        [toolbar setAutosavesConfiguration:NO];
        [toolbar setAllowsExtensionItems:NO];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];

        [window setToolbar:toolbar];
        
        NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
        NSRect windowFrame = NSMakeRect(screenVisibleFrame.origin.x, screenVisibleFrame.origin.y, 800, 600);

        [window setFrame:windowFrame display:NO];
        [window center];

        [[self resizerKnob] setHidden:YES];

        [window setFrameAutosaveName:@"CanvasWindow"];

        [windowContentView addSubview:_bottomView];
        [_bottomView setFrame:[window contentLayoutRect]];
    }
    
    [self setWindow:window];

    _canvasWindow    = window;
    _windowIsOverlay = usesOverlayWindow;
}


static void sAnimate(CanvasWindowController *self, AnimationAction action, id argument, CGFloat *outDuration)
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL usesOverlayWindow = [preferences usesOverlayWindow];

    CGFloat outDurationValue = 0;

    static CGRect                 sScrollRectInWindow    = {0};
    static NSView                *sTransitionImageView   = nil;
    static NSView                *sShieldImageView       = nil;
    static GratuitousDelayButton *sGratuitousDelayButton = nil;
    
    const CGFloat sFadeInDuration  = 0.25;
    const CGFloat sFadeOutDuration = 0.25;

    NSScrollView *canvasScrollView    = self->_canvasScrollView;
    Toolbox      *toolbox             = self->_toolbox;
    ContentView  *shroudView          = self->_shroudView;
    ContentView  *contentView         = self->_contentView;
    ShadowView   *shadowView          = self->_shadowView;
    CanvasView   *canvasView          = self->_canvasView;

    if (action == AnimationAction_DoOrderIn) {
        LOG(@"Order in");

        [canvasScrollView  setHidden:NO];
        [[self bottomView] setHidden:NO];

        [sTransitionImageView removeFromSuperview];
        sTransitionImageView = nil;

        [sShieldImageView removeFromSuperview];
        sShieldImageView = nil;

        [sGratuitousDelayButton removeFromSuperview];
        sGratuitousDelayButton = nil;

        NSDisableScreenUpdates();

        if (usesOverlayWindow) {
            sAnimate( self, AnimationAction_SetupTransitionImageView, nil, NULL);

            [shroudView  setAlphaValue:0];
            [contentView setAlphaValue:0];
            [shadowView  setAlphaValue:0];
        }

        [[self window] display];

#if ENABLE_APP_STORE && !defined(DEBUG)
        B_CheckReceipt();
#endif

#if ENABLE_TRIAL
        NSTimeInterval duration, unused;
        sGetPleaDuration(&unused, &duration);
        
        if (duration && (sTransitionImage || sShowDelayNextTime)) {
            sAnimate( self, AnimationAction_SetupShield, nil, &outDurationValue);
            sAnimate( self, AnimationAction_SetupGratuitousButton, nil, NULL);
        }
#endif

        NSEnableScreenUpdates();

        if (usesOverlayWindow) {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:sFadeInDuration];
                sAnimate( self, AnimationAction_RunFadeInOverlayAnimation, nil, NULL);

            } completionHandler:^{
                sAnimate( self, AnimationAction_FinishFadeInOverlayAnimation, nil, NULL);
            }];

            if (!sTransitionImageView) {
                sAnimate( self, AnimationAction_RunPopInOverlayAnimation, nil, NULL);
            }

        } else if (sShieldImageView) {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [context setDuration:sFadeInDuration];
                sAnimate( self, AnimationAction_RunFadeInShieldAnimation, nil, NULL);

            } completionHandler:^{
                sAnimate( self, AnimationAction_FinishFadeInShieldAnimation, nil, NULL);
            }];
        }

    } else if (action == AnimationAction_SetupTransitionImageView) {
        LOG(@"Setup Transition Image View");

        if (sTransitionImage) {
            NSView *windowContentView = [[self window] contentView];

            [canvasScrollView tile];
            [canvasScrollView setHidden:YES];

            
            NSRect appKitRect = [NSScreen winch_convertRectFromGlobal:sTransitionImageGlobalRect];
            CGRect frame = [[self window] convertRectFromScreen:appKitRect];
            frame = [windowContentView convertRect:frame fromView:nil];

            [sTransitionImageView removeFromSuperview];
            sTransitionImageView = [[NSView alloc] initWithFrame:frame];
            [sTransitionImageView setWantsLayer:YES];
            [[sTransitionImageView layer] setMagnificationFilter:kCAFilterNearest];
            [[sTransitionImageView layer] setContents:(__bridge id)sTransitionImage];

            [sTransitionImageView setFrame:frame];

            [windowContentView addSubview:sTransitionImageView];

            sScrollRectInWindow = [canvasView convertRect:[canvasView bounds] toView:nil];
        }

    } else if (action == AnimationAction_SetupShield) {
        LOG(@"Setup Shield");

        NSView *bottomView = [self bottomView];
        NSRect  bounds     = [bottomView bounds];
        CGFloat scale      = [[self window] backingScaleFactor];
        
        [bottomView setNeedsDisplay];
        [bottomView displayIfNeeded];
        
        CGImageRef shieldImage = CreateImage(bounds.size, NO, scale, ^(CGContextRef context) {
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, bounds.size.height);
            CGContextConcatCTM(context, flipVertical);
            [[bottomView layer] renderInContext:context];
        });
        
        [sShieldImageView removeFromSuperview];

        sShieldImageView = [[NSView alloc] initWithFrame:[bottomView frame]];
        [sShieldImageView setWantsLayer:YES];
        [[sShieldImageView layer] setContents:(__bridge id)shieldImage];
        [[sShieldImageView layer] setContentsScale:scale];

        CGImageRelease(shieldImage);
        
        [[bottomView superview] addSubview:sShieldImageView];
        [bottomView setHidden:YES];
        
        NSTimeInterval duration, unused;
        sGetPleaDuration(&duration, &unused);

        [sShieldImageView setAlphaValue:0.15];

        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:duration];
        [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];

        [sShieldImageView setAlphaValue:0.16];

        [NSAnimationContext endGrouping];
        
        outDurationValue = duration + sFadeInDuration;

    } else if (action == AnimationAction_CleanupShield) {
        LOG(@"Cleanup Shield");

        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
            [[self bottomView] setHidden:NO];

            [sShieldImageView removeFromSuperview];
            sShieldImageView = nil;
            
            [sGratuitousDelayButton removeFromSuperview];
            sGratuitousDelayButton = nil;

            [sTransitionImageView removeFromSuperview];
            sTransitionImageView = nil;
            
            CGImageRelease(sTransitionImage);
            sTransitionImage = NULL;

            sTransitionImageGlobalRect = CGRectZero;
        }];

        [[NSAnimationContext currentContext] setDuration:sFadeOutDuration];
        [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];

        [[sTransitionImageView   animator] setAlphaValue:1.0];
        [[sShieldImageView       animator] setAlphaValue:1.0];
        [[sGratuitousDelayButton animator] setAlphaValue:0.0];

        [NSAnimationContext endGrouping];

    } else if (action == AnimationAction_SetupGratuitousButton) {
        LOG(@"Setup Gratuitous Button");

        NSView *superview = [[self window] contentView];

        CGRect superBounds = [superview bounds];
        CGRect frame = NSMakeRect(0, 0, 410, 346);
        
        frame.origin.x = round((superBounds.size.width  - frame.size.width)  / 2);
        frame.origin.y = round((superBounds.size.height - frame.size.height) / 2);
        
        [sGratuitousDelayButton removeFromSuperview];
        sGratuitousDelayButton = [[GratuitousDelayButton alloc] initWithFrame:frame];
        [sGratuitousDelayButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin|NSViewMinXMargin|NSViewMinYMargin];
        
        [sGratuitousDelayButton setAlphaValue:0];
        
        [[[self window] contentView] addSubview:sGratuitousDelayButton];

    } else if (action == AnimationAction_RunFadeInOverlayAnimation) {
        LOG(@"Run Fade In Overlay");

        [[shroudView             animator] setAlphaValue:1.0];
        [[contentView            animator] setAlphaValue:1.0];
        [[shadowView             animator] setAlphaValue:1.0];
        [[sGratuitousDelayButton animator] setAlphaValue:1.0];

        if (sTransitionImageView) {
            [[sTransitionImageView animator] setFrame:sScrollRectInWindow];
            
            if (sShieldImageView) {
                [[sTransitionImageView animator] setAlphaValue:0.15];
            }
        }
    
    } else if (action == AnimationAction_FinishFadeInOverlayAnimation) {
        LOG(@"Finish Fade In Overlay");

        NSDisableScreenUpdates();
        
        [canvasScrollView setHidden:NO];

        for (Tool *tool in [toolbox allTools]) {
            [tool canvasWindowDidAppear];
        }

        if (!sShieldImageView) {
            [sTransitionImageView removeFromSuperview];
            sTransitionImageView = nil;
            
            CGImageRelease(sTransitionImage);
            sTransitionImage = NULL;

            sTransitionImageGlobalRect = CGRectZero;
        }

        [[self window] display];
    
        NSEnableScreenUpdates();

        if (sGratuitousDelayButton) {
            NSTimeInterval duration, unused;
            sGetPleaDuration(&duration, &unused);

            CAMediaTimingFunction *linear = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

            [CATransaction flush];

            [CATransaction begin];
            [CATransaction setAnimationDuration:duration];
            [CATransaction setAnimationTimingFunction:linear];

            [[sGratuitousDelayButton maskLayer] setTransform:CATransform3DIdentity];

            [CATransaction commit];
        }

    } else if (action == AnimationAction_RunFadeInShieldAnimation) {
        LOG(@"Run Fade In Shield");
        
        [[sGratuitousDelayButton animator] setAlphaValue:1.0];
        
        if (sShieldImageView) {
            [[sTransitionImageView animator] setAlphaValue:0.15];
        }
    
    } else if (action == AnimationAction_FinishFadeInShieldAnimation) {
        LOG(@"Finish Fade In Shield");

        [canvasScrollView setHidden:NO];

        for (Tool *tool in [toolbox allTools]) {
            [tool canvasWindowDidAppear];
        }
    
        if (sGratuitousDelayButton) {
            NSTimeInterval duration, unused;
            sGetPleaDuration(&duration, &unused);

            CAMediaTimingFunction *linear = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

            [CATransaction flush];

            [CATransaction begin];
            [CATransaction setAnimationDuration:duration];
            [CATransaction setAnimationTimingFunction:linear];

            [[sGratuitousDelayButton maskLayer] setTransform:CATransform3DIdentity];

            [CATransaction commit];
        }
    
    } else if (action == AnimationAction_RunPopInOverlayAnimation) {
        LOG(@"Run Pop In Overlay");

        CGSize contentViewBoundsSize = [contentView bounds].size;

        CGAffineTransform fromTransform = CGAffineTransformIdentity;
        fromTransform = CGAffineTransformTranslate(fromTransform, contentViewBoundsSize.width / 4, contentViewBoundsSize.height / 4);
        fromTransform = CGAffineTransformScale(fromTransform, 0.5, 0.5);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [animation setDuration:sFadeInDuration];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [animation setFromValue:[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(fromTransform)]];
        [animation setToValue:  [NSValue valueWithCATransform3D:CATransform3DIdentity]];
        [animation setFillMode:kCAFillModeBoth];

        [[contentView layer] addAnimation:animation forKey:@"transform"];
        [[shadowView  layer] addAnimation:animation forKey:@"transform"];
    }

    // Order out animation
    if (action == AnimationAction_DoOrderOut) {
        sShowDelayNextTime = (sShieldImageView != nil);

        if (usesOverlayWindow) {
            CGSize size = [contentView bounds].size;

            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setCompletionHandler:^{ sAnimate(self, AnimationAction_FinishOrderOutAnimation, nil, NULL); }];
            [[NSAnimationContext currentContext] setDuration:0.25];

            sAnimate(self, AnimationAction_RunOrderOutAnimation, nil, NULL);

            [NSAnimationContext endGrouping];

            if (!sShieldImageView) {
                CGAffineTransform fromTransform = CGAffineTransformIdentity;
                fromTransform = CGAffineTransformTranslate(fromTransform, size.width / 4, size.height / 4);
                fromTransform = CGAffineTransformScale(fromTransform, 0.5, 0.5);
                
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
                [animation setDuration:0.25];
                [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
                [animation setFromValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]];
                [animation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(fromTransform)]];
                [animation setFillMode:kCAFillModeBoth];
                
                [[contentView      layer] addAnimation:animation forKey:@"transform"];
                [[shadowView       layer] addAnimation:animation forKey:@"transform"];
            }

        } else {
            [[self window] orderOut:self];
        }

    } else if (action == AnimationAction_RunOrderOutAnimation) {
        [[shroudView  animator] setAlphaValue:0.0];
        [[contentView animator] setAlphaValue:0.0];
        [[shadowView  animator] setAlphaValue:0.0];
    
        [[sTransitionImageView   animator] setAlphaValue:0.0];
        [[sShieldImageView       animator] setAlphaValue:0.0];
        [[sGratuitousDelayButton animator] setAlphaValue:0.0];
    
    } else if (action == AnimationAction_FinishOrderOutAnimation) {
        [[self window] orderOut:self];

        [sTransitionImageView removeFromSuperview];
        sTransitionImageView = nil;

        [sShieldImageView removeFromSuperview];
        sShieldImageView = nil;

        [sGratuitousDelayButton removeFromSuperview];
        sGratuitousDelayButton = nil;
    }
    
    
    if (action == AnimationAction_UpdateOverlayForScreen) {
        if (!usesOverlayWindow) return;
        
        NSScreen *screen = (NSScreen *)argument;

        CGRect entireFrame  = [screen frame];
        CGRect visibleFrame = [screen visibleFrame];
        
        CGFloat leftEdge   = CGRectGetMinX(visibleFrame) - CGRectGetMinX(entireFrame);
        CGFloat topEdge    = CGRectGetMinY(visibleFrame) - CGRectGetMinY(entireFrame);

        CGFloat rightEdge  = CGRectGetMaxX(entireFrame) - CGRectGetMaxX(visibleFrame);
        CGFloat bottomEdge = CGRectGetMaxY(entireFrame) - CGRectGetMaxY(visibleFrame);

        CGFloat leftRight = leftEdge > rightEdge ? leftEdge : rightEdge;
        CGFloat topBottom = topEdge > bottomEdge ? topEdge : bottomEdge;
        
        [[self window] setFrame:entireFrame display:NO];

        CGRect contentRect = [[[self window] contentView] bounds];
        contentRect = CGRectInset(contentRect, leftRight + 16, topBottom + 16);

        // Limit to prevent huge window on large displays
        if (contentRect.size.width > 1920) {
            contentRect.size.width = 1920;
            contentRect.origin.x = round((entireFrame.size.width - contentRect.size.width) / 2);
        }

        // Check to see if we had a saved size for this display
        NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"OverlaySizes"];
        NSString     *sizeString = [dictionary objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)[screen winch_CGDirectDisplayID]]];
        
        if (sizeString) {
            CGSize size = NSSizeFromString(sizeString);
            
            size.width  = round(size.width);
            size.height = round(size.height);
            
            if ((size.width < contentRect.size.width) && (size.height < contentRect.size.height)) {
                contentRect.size = size;
                contentRect.origin.x = round((entireFrame.size.width  - contentRect.size.width)  / 2);
                contentRect.origin.y = round((entireFrame.size.height - contentRect.size.height) / 2);
            }
        }

        [contentView setFrame:contentRect];
        [shadowView  setFrame:contentRect];
    }
    
    if (outDuration) *outDuration = outDurationValue;
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    for (CanvasObjectView *view in [_GUIDToViewMap allValues]) {
        [view preferencesDidChange:preferences];
    }
    
    BOOL usesOverlayWindow = [preferences usesOverlayWindow];
    if (usesOverlayWindow != _windowIsOverlay) {
        [self _updateWindowsForOverlayMode];
    }
}


- (void) _handleApplicationDidResignActiveNotification:(NSNotification *)note
{
    if (!IsInDebugger()) {
        [self hide];
    }
}


- (void) _updateSelectedObject
{
    NSArray *objects = [_canvas selectedObjects];
    NSInteger count = [objects count];

    if (count > 1) {
        [self setSelectedObject:NSMultipleValuesMarker];
    } else if (count == 1) {
        [self setSelectedObject:[objects lastObject]];
    } else {
        [self setSelectedObject:NSNoSelectionMarker];
    }
}


- (void) _updateInspector
{
    Tool *selectedTool = [_toolbox selectedTool];
    Tool *grappleTool  = (Tool *)[_toolbox grappleTool];
    NSView *view = nil;

    if (selectedTool == [_toolbox zoomTool]) {
        view = [self zoomToolView];
    } else if (grappleTool && (selectedTool == grappleTool)) {
        view = [self grappleToolView];
    }
    
    if ([view superview] != _inspectorContainer) {
        NSArray *subviews = [[_inspectorContainer subviews] copy];

        for (NSView *subview in subviews) {
            [subview removeFromSuperview];
        }
        
        [_inspectorContainer addSubview:view];
        [view setFrame:[_inspectorContainer bounds]];
    }
}


- (void) _updateCanvasWithLibraryItem:(LibraryItem *)item
{
    Screenshot *screenshot = [item screenshot];

    // Step two, update canvas if needed
    if ([_canvas screenshot] != screenshot) {
        _GUIDToViewMap        = [NSMutableDictionary dictionary];
        _GUIDToResizeKnobsMap = [NSMutableDictionary dictionary];

        [self saveCurrentLibraryItem];
        
        Canvas *canvas = [[Canvas alloc] initWithDelegate:self];
        _canvas = canvas;
        _currentLibraryItem = item;
        if (_currentLibraryItem) {
            [_libraryArrayController setSelectedObjects:@[ _currentLibraryItem ] ];
        } else {
            [_libraryArrayController setSelectedObjects:@[ ]];
        }

        for (Tool *tool in [_toolbox allTools]) {
            [tool reset];
        }

        if (canvas) {
            CanvasView *canvasView = [[CanvasView alloc] initWithFrame:CGRectZero canvas:canvas];
            [canvasView setDelegate:self];
            
            _canvasView = canvasView;
            [_magnificationManager setCanvasView:_canvasView];

            [_canvasScrollView setDocumentView:canvasView];
        } else {
            _canvasView = nil;
            [_magnificationManager setCanvasView:nil];

            [_canvasScrollView setDocumentView:[[NSView alloc] init]];
        }
        
        NSDictionary *dictionary = [item canvasDictionary];
        [canvas setupWithScreenshot:screenshot dictionary:dictionary];

        [_canvasView sizeToFit];
    }

    // Step three, figure out magnification level
    {
        NSSize  availableSize = [_canvasScrollView documentVisibleRect].size;
        CGFloat backingScale  = [[_canvasScrollView window] backingScaleFactor];
        
        availableSize.width  *= backingScale;
        availableSize.height *= backingScale;
        
        NSSize canvasSize    = [_canvas size];

        CGFloat xScale = availableSize.width / canvasSize.width;
        CGFloat yScale = availableSize.height / canvasSize.height;

        NSArray *levels = [_magnificationManager levelsForSlider];
        NSInteger index = [_magnificationManager indexInArray:levels forMagnification:(xScale < yScale ? xScale : yScale)];

        CGFloat level = [[levels objectAtIndex:index] doubleValue];
        [_magnificationManager setMagnification:level];
    }
}


#pragma mark - Selection

- (NSScreen *) _preferredScreenForOverlayWithScreenshotRect:(NSRect *)screenshotRect
{
    PreferredDisplay preferredDisplay = [[Preferences sharedInstance] preferredDisplay];

    NSScreen *preferredScreen = nil;
    if (preferredDisplay == PreferredDisplayMain) {
        preferredScreen = [[NSScreen screens] firstObject];
    } else if ((preferredDisplay == PreferredDisplaySame) && screenshotRect) {
        preferredScreen = [NSScreen winch_screenWithGlobalRect:*screenshotRect];
    } else {
        preferredScreen = [NSScreen winch_screenWithCGDirectDisplayID:preferredDisplay];
    }

    if (!preferredScreen) {
        preferredScreen = [[NSScreen screens] firstObject];
    }
    
    return preferredScreen;
}


- (BOOL) _deleteSelectedObjects
{
    NSArray *selectedObjects = [_canvas selectedObjects];
    
    if ([selectedObjects count]) {
        for (CanvasObject *selectedObject in selectedObjects) {
            [_canvas removeCanvasObject:selectedObject];
        }

        return YES;
    }
    
    return NO;
}


- (BOOL) _moveSelectionWithArrowKey:(unichar)key delta:(CGFloat)delta
{
    CanvasObject *selectedObject = [self selectedObject];
    ObjectEdge edge = _selectedEdge;

    if ([selectedObject isKindOfClass:[CanvasObject class]]) {
        if (edge == ObjectEdgeNone) {
            CGRect rect = [selectedObject rect];

            if (key == NSUpArrowFunctionKey) {
                rect.origin.y -= delta;
            } else if (key == NSDownArrowFunctionKey) {
                rect.origin.y += delta;
            } else if (key == NSLeftArrowFunctionKey) {
                rect.origin.x -= delta;
            } else if (key == NSRightArrowFunctionKey) {
                rect.origin.x += delta;
            }
            
            [selectedObject setRect:rect];

        } else {
            CGRect rect = [selectedObject rect];
            
            if (key == NSUpArrowFunctionKey || key == NSLeftArrowFunctionKey) {
                delta = -delta;
            }
        
            if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey) {
                if (edge == ObjectEdgeTopLeft || edge == ObjectEdgeTop || edge == ObjectEdgeTopRight) {
                    CGFloat value = GetEdgeValueOfRect(rect, CGRectMinYEdge);
                    value += delta;
                    rect = GetRectByAdjustingEdge(rect, CGRectMinYEdge, value);

                } else if (edge == ObjectEdgeBottomLeft || edge == ObjectEdgeBottom || edge == ObjectEdgeBottomRight) {
                    CGFloat value = GetEdgeValueOfRect(rect, CGRectMaxYEdge);
                    value += delta;
                    rect = GetRectByAdjustingEdge(rect, CGRectMaxYEdge, value);
                }

            } else {
                if (edge == ObjectEdgeTopLeft || edge == ObjectEdgeLeft || edge == ObjectEdgeBottomLeft) {
                    CGFloat value = GetEdgeValueOfRect(rect, CGRectMinXEdge);
                    value += delta;
                    rect = GetRectByAdjustingEdge(rect, CGRectMinXEdge, value);

                } else if (edge == ObjectEdgeTopRight || edge == ObjectEdgeRight || edge == ObjectEdgeBottomRight) {
                    CGFloat value = GetEdgeValueOfRect(rect, CGRectMaxXEdge);
                    value += delta;
                    rect = GetRectByAdjustingEdge(rect, CGRectMaxXEdge, value);
                }
            }
    
            [selectedObject setRect:rect];
        }

        return YES;
    }
    
    return NO;
}


- (ObjectEdge) _edgeOfRectangleByApplyingArrowKey:(unichar)key toEdge:(ObjectEdge)edge
{
    const BOOL isLeftArrow  = (key == NSLeftArrowFunctionKey);
    const BOOL isRightArrow = (key == NSRightArrowFunctionKey);
    const BOOL isUpArrow    = (key == NSUpArrowFunctionKey);
    const BOOL isDownArrow  = (key == NSDownArrowFunctionKey);
    
    if (edge == ObjectEdgeTop || edge == ObjectEdgeBottom) {
        if      (isLeftArrow)  return (edge == ObjectEdgeTop) ? ObjectEdgeTopLeft  : ObjectEdgeBottomLeft;
        else if (isRightArrow) return (edge == ObjectEdgeTop) ? ObjectEdgeTopRight : ObjectEdgeBottomRight;
        else if (isUpArrow)    return ObjectEdgeTop;
        else if (isDownArrow)  return ObjectEdgeBottom;

    } else if (edge == ObjectEdgeLeft || edge == ObjectEdgeRight) {
        if      (isUpArrow)    return (edge == ObjectEdgeLeft) ? ObjectEdgeTopLeft    : ObjectEdgeTopRight;
        else if (isDownArrow)  return (edge == ObjectEdgeLeft) ? ObjectEdgeBottomLeft : ObjectEdgeBottomRight;
        else if (isLeftArrow)  return ObjectEdgeLeft;
        else if (isRightArrow) return ObjectEdgeRight;

    } else if (edge == ObjectEdgeTopLeft) {
        if (isRightArrow) return ObjectEdgeTop;
        if (isDownArrow)  return ObjectEdgeLeft;

    } else if (edge == ObjectEdgeTopRight) {
        if (isLeftArrow) return ObjectEdgeTop;
        if (isDownArrow) return ObjectEdgeRight;

    } else if (edge == ObjectEdgeBottomLeft) {
        if (isRightArrow) return ObjectEdgeBottom;
        if (isUpArrow)    return ObjectEdgeLeft;

    } else if (edge == ObjectEdgeBottomRight) {
        if (isLeftArrow) return ObjectEdgeBottom;
        if (isUpArrow)   return ObjectEdgeRight;

    } else if (edge == ObjectEdgeNone) {
        if (isUpArrow)    return ObjectEdgeTop;
        if (isDownArrow)  return ObjectEdgeBottom;
        if (isLeftArrow)  return ObjectEdgeLeft;
        if (isRightArrow) return ObjectEdgeRight;
    }
    
    return edge;
}


- (BOOL) _selectEdgeWithArrowKey:(unichar)key
{
    NSArray *selectedObjects = [_canvas selectedObjects];
    CanvasObject *object = [selectedObjects count] == 1 ? [selectedObjects lastObject] : nil;
    
    if (!object) {
        return NO;
    }
    
    ObjectEdge newSelectedEdge = ObjectEdgeNone;
    
    if ([object isKindOfClass:[Rectangle class]]) {
        newSelectedEdge = [self _edgeOfRectangleByApplyingArrowKey:key toEdge:_selectedEdge];

    } else if ([object isKindOfClass:[Line class]]) {
        Line *line = (Line *)object;

        if ([line isVertical]) {
            if (key == NSUpArrowFunctionKey) {
                newSelectedEdge = ObjectEdgeTop;
            } else if (key == NSDownArrowFunctionKey) {
                newSelectedEdge = ObjectEdgeBottom;
            } else {
                return NO;
            }
            
        } else {
            if (key == NSLeftArrowFunctionKey) {
                newSelectedEdge = ObjectEdgeLeft;
            } else if (key == NSRightArrowFunctionKey) {
                newSelectedEdge = ObjectEdgeRight;
            } else {
                return NO;
            }
        }
    }
    
    [self _updateSelectedEdge:newSelectedEdge];
    
    return YES;
}


- (void) _updateSelectedEdge:(ObjectEdge)edge
{
    NSArray *selectedObjects = [_canvas selectedObjects];
    CanvasObject *object = [selectedObjects count] == 1 ? [selectedObjects lastObject] : nil;
    if (!object) return;

    _selectedEdge = edge;
    
    NSArray  *resizeKnobs = [_GUIDToResizeKnobsMap objectForKey:[object GUID]];
 
    for (ResizeKnobView *knob in resizeKnobs) {
        if ([knob edge] == _selectedEdge) {
            [knob setHighlighted:[[[knob owningObjectView] canvasObject] isEqual:object]];
        } else {
            [knob setHighlighted:NO];
        }
    }
}


- (BOOL) _shrinkCurrentSelection
{
    return NO;
}


- (BOOL) _expandCurrentSelection
{
    return NO;
}


- (BOOL) _duplicateCurrentSelection
{
    NSMutableArray *duplicates = [NSMutableArray array];

    for (CanvasObject *object in [_canvas selectedObjects]) {
        CanvasObject *duplicate = [object duplicate];

        if (duplicate) {
            CGRect rect = [duplicate rect];
            rect.origin.x += 10;
            rect.origin.y += 10;
            [duplicate setRect:rect];
            
            [_canvas addCanvasObject:duplicate];
            [duplicates addObject:duplicate];
        }
    }

    CanvasObject *lastDuplicate = [duplicates lastObject];
    if (lastDuplicate) {
        [_canvas unselectAllObjects];
        [_canvas selectObject:lastDuplicate];
    }

    return (lastDuplicate != nil);
}


#pragma mark - Canvas Delegate

- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object
{
    CanvasObjectView *view = nil;

    if ([object isKindOfClass:[Guide class]]) {
        GuideObjectView *guideObjectView = [[GuideObjectView alloc] initWithFrame:NSZeroRect];
        [guideObjectView setGuide:(Guide *)object];
        view = guideObjectView;

    } else if ([object isKindOfClass:[Line class]]) {
        LineObjectView *lineObjectView = [[LineObjectView alloc] initWithFrame:NSZeroRect];
        [lineObjectView setLine:(Line *)object];
        view = lineObjectView;

    } else if ([object isKindOfClass:[Rectangle class]]) {
        RectangleObjectView *rectangleObjectView = [[RectangleObjectView alloc] initWithFrame:NSZeroRect];
        [rectangleObjectView setRectangle:(Rectangle *)object];
        view = rectangleObjectView;

    } else if ([object isKindOfClass:[Marquee class]]) {
        MarqueeObjectView *marqueeObjectView = [[MarqueeObjectView alloc] initWithFrame:NSZeroRect];
        [marqueeObjectView setMarquee:(Marquee *)object];
        view = marqueeObjectView;
    }
    
    if (view) {
        [_GUIDToViewMap setObject:view forKey:[object GUID]];
        [_canvasView addCanvasObjectView:view];
    }
}


- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object
{
    CanvasObjectView *layer = [self viewForCanvasObject:object];

    if (layer) {
        [_canvasView updateCanvasObjectView:layer];
    }
}


- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object
{
    CanvasObjectView *view = [self viewForCanvasObject:object];

    if (view) {
        [_canvasView removeCanvasObjectView:view];
    }
}


- (void) canvas:(Canvas *)canvas didSelectObject:(CanvasObject *)object
{
    NSString *GUID = [object GUID];

    if (!_GUIDToResizeKnobsMap) {
        _GUIDToResizeKnobsMap = [NSMutableDictionary dictionary];
    }

    if (![_GUIDToResizeKnobsMap objectForKey:GUID]) {
        NSMutableArray *resizeKnobs = [NSMutableArray array];

        [_GUIDToResizeKnobsMap setObject:resizeKnobs forKey:GUID];
        
        void (^addResizeKnob)(CanvasObjectView *, ObjectEdge) = ^(CanvasObjectView *parent, ObjectEdge edge) {
            ResizeKnobView *knob = [[ResizeKnobView alloc] initWithFrame:NSZeroRect];
            
            [knob setEdge:edge];
            [knob setOwningObjectView:parent];
        
            [_canvasView addCanvasObjectView:knob];
        
            [resizeKnobs addObject:knob];
        };

        CanvasObjectView *parentView = [self viewForCanvasObject:object];
        NSArray *resizeKnobEdges = [parentView resizeKnobEdges];

        for (NSNumber *resizeKnobEdge in resizeKnobEdges) {
            addResizeKnob(parentView, [resizeKnobEdge integerValue]);
        }
    }

    [self _updateSelectedEdge:ObjectEdgeNone];
    
    [self _updateSelectedObject];
}


- (void) canvas:(Canvas *)canvas didUnselectObject:(CanvasObject *)object
{
    NSString *GUID = [object GUID];
    NSArray  *resizeKnobs = [_GUIDToResizeKnobsMap objectForKey:GUID];
 
    [self _updateSelectedEdge:ObjectEdgeNone];
    
    for (ResizeKnobView *knob in resizeKnobs) {
        [knob setOwningObjectView:nil];
        [_canvasView removeCanvasObjectView:knob];
    }

    [_GUIDToResizeKnobsMap removeObjectForKey:GUID];

    [self _updateSelectedObject];
}


- (void) canvasDidChangeHiddenGroupNames:(Canvas *)canvas
{
    GrappleTool *grappleTool = [_toolbox grappleTool];

    if ([[_toolbox selectedTool] isEqual:grappleTool]) {
        [grappleTool updatePreviewGrapple];
    }
}


#pragma mark - CanvasView Delegate


- (CanvasObjectView *) canvasView:(CanvasView *)view duplicateObjectView:(CanvasObjectView *)objectView
{
    CanvasObject *duplicate = [[objectView canvasObject] duplicate];
    if (!duplicate) return nil;
    
    [[view canvas] addCanvasObject:duplicate];
    
    return [self viewForCanvasObject:duplicate];
}


- (void) canvasView:(CanvasView *)view objectViewDoubleClick:(CanvasObjectView *)objectView
{
    if ([objectView isKindOfClass:[ResizeKnobView class]]) {
        ResizeKnobView *knobView = (ResizeKnobView *)objectView;
        CanvasObject *object = [[knobView owningObjectView] canvasObject];

        ObjectEdge edge = [knobView edge];

        [self setSelectedObject:object];
        [self _updateSelectedEdge:edge];
    }
}


- (void) canvasView:(CanvasView *)view didFinalizeNewbornWithView:(CanvasObjectView *)objectView
{
    CanvasObject *object = [objectView canvasObject];
    
    // Don't do this for grapple yet, only Rectangle and Line
    if ([[_toolbox selectedTool] isEqual:[_toolbox grappleTool]]) {
        return;
    }
    
    if ([object isKindOfClass:[Rectangle class]] ||
        [object isKindOfClass:[Line class]])
    {
        [_canvas unselectAllObjects];
        [_canvas selectObject:object];
    }
}


- (BOOL) canvasView:(CanvasView *)view shouldTrackObjectView:(CanvasObjectView *)objectView
{
    Tool *selectedTool = [_toolbox selectedTool];
    BOOL isMoveTool = (selectedTool == [_toolbox moveTool]);

    // Guides are only clickable with Move tool
    //
    if ([objectView isKindOfClass:[GuideObjectView class]]) {
        return isMoveTool;

    // Marquees are only clickable with Marquee tool
    //
    } else if ([objectView isKindOfClass:[MarqueeObjectView class]]) {
        return selectedTool == [_toolbox marqueeTool];

    // Resize knobs are ALWAYS clickable unless tool is Zoom or Hand
    //
    } else if ([objectView isKindOfClass:[ResizeKnobView class]]) {
        return (selectedTool != [_toolbox handTool]) && (selectedTool != [_toolbox zoomTool]);

    // Lines are clickable in Line and Move, unless it's a temporary line
    //
    } else if ([objectView isKindOfClass:[LineObjectView class]]) {
        Line *line = (Line *)[objectView canvasObject];

        if ([line isPreview]) {
            return NO;
        }
        
        Tool *grappleTool = (Tool *)[_toolbox grappleTool];
        BOOL isGrappleTool = grappleTool && (selectedTool == grappleTool);
        
        return isMoveTool || isGrappleTool || (selectedTool == [_toolbox lineTool]);

    // Rectangles are clickable in Rectangle and Move
    //
    } else if ([objectView isKindOfClass:[RectangleObjectView class]]) {
        return isMoveTool || (selectedTool == [_toolbox rectangleTool]);
    }
    
    return NO;
}


- (void) canvasView:(CanvasView *)view willTrackObjectView:(CanvasObjectView *)objectView
{
    Tool         *selectedTool = [_toolbox selectedTool];
    CanvasObject *canvasObject = [objectView canvasObject];

    if ([selectedTool canSelectCanvasObject:canvasObject] && [canvasObject isSelectable]) {
        [_canvas unselectAllObjects];
        [_canvas selectObject:canvasObject];
    }
}


- (void) canvasView:(CanvasView *)view didTrackObjectView:(CanvasObjectView *)objectView
{
    // No op
}


- (NSCursor *) cursorForCanvasView:(CanvasView *)view
{
    return [[_toolbox selectedTool] cursor];
}


- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event
{
    [[_toolbox selectedTool] mouseMovedWithEvent:event];
}


- (void) canvasView:(CanvasView *)view mouseExitedWithEvent:(NSEvent *)event
{
    [[_toolbox selectedTool] mouseExitedWithEvent:event];
}


- (BOOL) canvasView:(CanvasView *)canvasView mouseDownWithEvent:(NSEvent *)event
{
    return [[_toolbox selectedTool] mouseDownWithEvent:event];
}


- (void) canvasView:(CanvasView *)view mouseDraggedWithEvent:(NSEvent *)event
{
    [[_toolbox selectedTool] mouseDraggedWithEvent:event];
}


- (void) canvasView:(CanvasView *)view mouseUpWithEvent:(NSEvent *)event
{
    [[_toolbox selectedTool] mouseUpWithEvent:event];
}

#pragma mark - Tool Owner

- (CanvasObjectView *) viewForCanvasObject:(CanvasObject *)object
{
    if (!object) return nil;
    return [_GUIDToViewMap objectForKey:[object GUID]];
}


- (void) zoomWithDirection:(NSInteger)direction event:(NSEvent *)event
{
    [_magnificationManager zoomWithDirection:direction event:event];
}


- (BOOL) isToolSelected:(Tool *)tool
{
    return [[_toolbox selectedTool] isEqual:tool];
}


#pragma mark - Other Delegates

- (void) contentView:(ContentView *)contentView clickedWithEvent:(NSEvent *)event
{
    if (contentView == _shroudView) {
        [self hide];
    } else if (contentView == _contentView) {
        [[self window] makeFirstResponder:[self window]];
    }
}


- (BOOL) rulerView:(RulerView *)rulerView mouseDownWithEvent:(NSEvent *)event
{
    Guide *guide = [Guide guideVertical:(rulerView == _verticalRuler)];
    [_canvas addCanvasObject:guide];
    
    CanvasObjectView *view = [self viewForCanvasObject:guide];
    [view trackWithEvent:event newborn:YES];

    if ([guide isValid]) {
        [_toolbox setSelectedToolName:[[_toolbox moveTool] name]];
    }

    return NO;
}


- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *result = [[NSToolbarItem alloc] initWithItemIdentifier:@"main"];

    [result setView:_topView];
    [result setMaxSize:NSMakeSize(9999, 40)];

    return result;
}


- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ @"main" ];
}


- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ @"main" ];
}


- (BOOL) window:(CanvasWindow *)window cancelOperation:(id)sender
{
    NSWindow *selfWindow = [self window];

    Preferences        *preferences         = [Preferences sharedInstance];
    CloseScreenshotsKey closeScreenshotsKey = [preferences closeScreenshotsKey];

    BOOL useEscapeToClose = (closeScreenshotsKey == CloseScreenshotsKeyEscape) ||
                            (closeScreenshotsKey == CloseScreenshotsKeyBoth);

    if ([selfWindow firstResponder] != selfWindow) {
        [selfWindow makeFirstResponder:selfWindow];

    } else if (_selectedEdge != ObjectEdgeNone) {
        [self _updateSelectedEdge:ObjectEdgeNone];

    } else if ([[_canvas selectedObjects] count]) {
        [_canvas unselectAllObjects];

    } else if (useEscapeToClose) {
        [self hide];
    }

    return YES;
}


- (void) windowResizerKnobWillStartDrag:(WindowResizerKnob *)knob
{
    _contentViewFrameAtResizeStart = [_contentView frame];

    NSRect windowRect = [[[self window] contentView] bounds];

    _contentViewMaxFrameAtResizeStart = NSInsetRect(windowRect, 32, 32);

    _contentViewMinFrameAtResizeStart = NSMakeRect(0, 0, 640, 480);
    _contentViewMinFrameAtResizeStart.origin.x = round((windowRect.size.width  - _contentViewMinFrameAtResizeStart.size.width)  / 2);
    _contentViewMinFrameAtResizeStart.origin.y = round((windowRect.size.height - _contentViewMinFrameAtResizeStart.size.height) / 2);
}


- (void) windowResizerKnob:(WindowResizerKnob *)knob didDragWithDeltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY
{
    NSRect frame = NSInsetRect(_contentViewFrameAtResizeStart, -deltaX, deltaY);

    if (frame.size.width > _contentViewMaxFrameAtResizeStart.size.width) {
        frame.origin.x   = _contentViewMaxFrameAtResizeStart.origin.x;
        frame.size.width = _contentViewMaxFrameAtResizeStart.size.width;
    }

    if (frame.size.height > _contentViewMaxFrameAtResizeStart.size.height) {
        frame.origin.y    = _contentViewMaxFrameAtResizeStart.origin.y;
        frame.size.height = _contentViewMaxFrameAtResizeStart.size.height;
    }

    if (frame.size.width < _contentViewMinFrameAtResizeStart.size.width) {
        frame.origin.x   = _contentViewMinFrameAtResizeStart.origin.x;
        frame.size.width = _contentViewMinFrameAtResizeStart.size.width;
    }

    if (frame.size.height < _contentViewMinFrameAtResizeStart.size.height) {
        frame.origin.y    = _contentViewMinFrameAtResizeStart.origin.y;
        frame.size.height = _contentViewMinFrameAtResizeStart.size.height;
    }

    [_contentView setFrame:frame];
    [_shadowView  setFrame:frame];
}


- (void) windowResizerKnobWillEndDrag:(WindowResizerKnob *)knob
{
    NSSize size = [_contentView frame].size;
    
    NSMutableDictionary *dictionary = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"OverlaySizes"] mutableCopy];
    
    if (!dictionary) {
        dictionary = [NSMutableDictionary dictionary];
    }
    
    NSString *key        = [NSString stringWithFormat:@"%lu", (unsigned long)[[[self window] screen] winch_CGDirectDisplayID]];
    NSString *sizeString = NSStringFromSize(size);
    
    if (sizeString && key) {
        [dictionary setObject:sizeString forKey:key];
    }

    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"OverlaySizes"];
}


- (BOOL) window:(CanvasWindow *)window performClose:(id)sender
{
    CloseScreenshotsKey closeScreenshotsKey = [[Preferences sharedInstance] closeScreenshotsKey];

    BOOL useCommandWToClose = (closeScreenshotsKey == CloseScreenshotsKeyCommandW) ||
                              (closeScreenshotsKey == CloseScreenshotsKeyBoth);

    if (useCommandWToClose) {
        [self hide];
        return YES;
    }

    return NO;
}


- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *)window
{
    return [_canvas undoManager];
}


#pragma mark - Public Methods / IBActions

- (BOOL) importFilesAtPaths:(NSArray *)filePaths
{
    LibraryItem *itemToOpen = nil;

    for (NSString *filePath in filePaths) {
        LibraryItem *item = [[Library sharedInstance] importedItemAtPath:filePath];
        if (item) itemToOpen = item;
    }

    if (itemToOpen) {
        NSWindow *window = [self window];

        [self _updateCanvasWithLibraryItem:itemToOpen];

        if (![window isVisible]) {
            [self toggleVisibility];
        }

        return YES;
    }

    return NO;
}


- (void) presentLibraryItem:(LibraryItem *)libraryItem fromGlobalRect:(CGRect)globalRect
{
    [self window];  // Force nib to load

    ProtectEntry();

    BOOL useZoomAnimation = NO;

    NSScreen *preferredScreen = [self _preferredScreenForOverlayWithScreenshotRect:&globalRect];

    if (!preferredScreen) {
        preferredScreen = [[NSScreen screens] firstObject];
    }

    // Determine which screens intersect the rect
    {
        NSArray *screens = [NSScreen winch_screensWithGlobalRect:globalRect];
        if ([screens containsObject:preferredScreen]) {
            useZoomAnimation = YES;
        }
    }

    // Set up transition image if we can use the zoom animation
    if (useZoomAnimation) {
        CGImageRef image = [[libraryItem screenshot] CGImage];

        CGImageRelease(sTransitionImage);
        sTransitionImage = CGImageRetain(image);
        sTransitionImageGlobalRect = globalRect;
    }

    NSDisableScreenUpdates();

    sAnimate(self, AnimationAction_UpdateOverlayForScreen, preferredScreen, NULL);
    [self _updateCanvasWithLibraryItem:libraryItem];

    NSView *viewToBlock = [[Preferences sharedInstance] usesOverlayWindow] ? _contentView : _bottomView;

    XUIView *blockerView = [[XUIView alloc] initWithFrame:[viewToBlock bounds]];
    [blockerView setBackgroundColor:[NSColor clearColor]];
    
    CGFloat outDuration = 0;
    sAnimate(self, AnimationAction_DoOrderIn, nil, &outDuration);

    if (outDuration) {
        LOG(@"Adding blocker, will remove after %g seconds", outDuration);

        [viewToBlock addSubview:blockerView];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(outDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            sAnimate(self, AnimationAction_CleanupShield, nil, NULL);
            [blockerView removeFromSuperview];
        });
    }

    [NSApp activateIgnoringOtherApps:YES];
    [[CursorInfo sharedInstance] setEnabled:YES];

    [[self window] makeKeyAndOrderFront:self];
    
    NSEnableScreenUpdates();

    [[self window] makeFirstResponder:[self window]];

    ProtectExit();
}


- (void) toggleVisibility
{
    if ([self isWindowVisible]) {
        [self hide];

    } else {
        NSScreen *preferredScreen = [self _preferredScreenForOverlayWithScreenshotRect:NULL];
        if (!preferredScreen) preferredScreen = [NSScreen mainScreen];

        sAnimate(self, AnimationAction_UpdateOverlayForScreen, preferredScreen, NULL);

        CGImageRelease(sTransitionImage);
        sTransitionImage = NULL;
        
        if (!_currentLibraryItem) {
            LibraryItem *item = [[[Library sharedInstance] items] lastObject];
            if (!item) {
                NSBeep();
                return;
            }

            [self _updateCanvasWithLibraryItem:item];
        }

        CGFloat outDuration = 0;
        sAnimate(self, AnimationAction_DoOrderIn, nil, &outDuration);

        if (outDuration) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(outDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                sAnimate(self, AnimationAction_CleanupShield, nil, NULL);
            });
        }

        [NSApp activateIgnoringOtherApps:YES];
        [[CursorInfo sharedInstance] setEnabled:YES];
        [[self window] makeKeyAndOrderFront:self];

        [[self window] makeFirstResponder:[self window]];
    }
}


- (void) saveCurrentLibraryItem
{
    if (_currentLibraryItem && _canvas) {
        NSDictionary *dictionary = [_canvas dictionaryRepresentation];
        [_currentLibraryItem setCanvasDictionary:dictionary];
    }
}


- (void) hide
{
    [self saveCurrentLibraryItem];

    [[CursorInfo sharedInstance] setEnabled:NO];
    
    sAnimate(self, AnimationAction_DoOrderOut, nil, NULL);
}


- (void) hideIfOverlay
{
    if (_windowIsOverlay && [[self window] isVisible]) {
        [self hide];
    }
}


- (BOOL) isWindowVisible
{
    if (!_windowIsOverlay && (([[self window] occlusionState] & NSWindowOcclusionStateVisible) == 0)) {
        return NO;
    }

    return [[self window] isVisible];
}


- (IBAction) copy:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];

    CanvasObject *objectToWrite = [self selectedObject];
    if (![objectToWrite isKindOfClass:[CanvasObject class]]) {
        objectToWrite = nil;
    }

    if ([_toolbox selectedTool] == [_toolbox marqueeTool]) {
        NSArray *marquees = [_canvas canvasObjectsWithGroupName:[Marquee groupName]];
        objectToWrite = [marquees lastObject];
    }
    
    if (![objectToWrite writeToPasteboard:pboard]) {
        CGImageRef cgImage = [[_currentLibraryItem screenshot] CGImage];
        
        if (cgImage) {
            NSImage *image = [NSImage imageWithCGImage:cgImage scale:1.0 orientation:XUIImageOrientationUp];

            [pboard clearContents];
            [pboard writeObjects:@[ image ] ];

        } else {
            NSBeep();
        }
    }
}


- (void) _loadNextOrPreviousLibraryItem:(NSInteger)offset
{
    NSIndexSet *selected = _librarySelectionIndexes;
    NSArray    *items    = [[Library sharedInstance] items];

    NSUInteger selectedIndex = [selected lastIndex];
    NSUInteger maxIndex = [items count] - 1;

    if (offset < 0 && (selectedIndex == 0)) {
        NSBeep();
        return;
    }
    
    selectedIndex += offset;

    if (selectedIndex > maxIndex) {
        NSBeep();
        return;
    }

    LibraryItem *itemToSelect = [items objectAtIndex:selectedIndex];
    [_libraryArrayController setSelectedObjects:@[ itemToSelect ] ];
}


- (IBAction) loadPreviousLibraryItem:(id)sender
{
    [self _loadNextOrPreviousLibraryItem:-1];
}


- (IBAction) loadNextLibraryItem:(id)sender
{
    [self _loadNextOrPreviousLibraryItem:1];
}


- (IBAction) deleteSelectedLibraryItem:(id)sender
{
    NSIndexSet *selected = _librarySelectionIndexes;
    NSArray    *items    = [[Library sharedInstance] items];

    NSUInteger selectedIndex = [selected lastIndex];
    NSUInteger maxIndex = [items count] - 1;

    LibraryItem *itemToRemove = [items objectAtIndex:selectedIndex];
    LibraryItem *itemToSelect = nil;
    
    if (selectedIndex < maxIndex) {
        itemToSelect = [items objectAtIndex:(selectedIndex + 1)];
    } else if (selectedIndex > 0) {
        itemToSelect = [items objectAtIndex:(selectedIndex - 1)];
    }

    if (itemToSelect) {
        [[Library sharedInstance] removeItem:itemToRemove];
        [_libraryArrayController setSelectedObjects:@[ itemToSelect ] ];

    } else {
        [[Library sharedInstance] removeItem:itemToRemove];
        [self hide];
    }
}


- (IBAction) zoomIn:(id)sender
{
    [_magnificationManager zoomIn];
}


- (IBAction) zoomOut:(id)sender
{
    [_magnificationManager zoomOut];
}


- (IBAction) toggleGuides:(id)sender
{
    NSString *guideGroupName = [Guide groupName];

    BOOL isHidden = [_canvas isGroupNameHidden:guideGroupName];
    [_canvas setGroupName:guideGroupName hidden:!isHidden];
}


- (IBAction) zoomTo:(id)sender
{
    NSInteger level = [sender tag];
    [_magnificationManager setMagnification:level];
}


- (IBAction) exportItem:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];

    [savePanel setNameFieldStringValue:@"Pixel Winch Image"];
    [savePanel setShowsTagField:NO];
    [savePanel setAllowedFileTypes:@[ @"public.png" ]];
    
    if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
        NSImage *snapshot = GetSnapshotImageForView(_canvasView);
        
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[snapshot TIFFRepresentation]];
        NSData *data = [rep representationUsingType:NSPNGFileType properties:nil];
        [data writeToURL:[savePanel URL] atomically:YES];
    }
}


- (IBAction) showGrappleHelp:(id)sender
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GrappleHelp" ofType:@"txt"];
    
    NSError  *error;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (!text) return;

    NSPopover *popover = [[NSPopover alloc] init];
    
    [popover setAppearance:NSPopoverAppearanceHUD];
    [popover setBehavior:NSPopoverBehaviorTransient];

    NSView *container = [[NSView alloc] init];

    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 360, 1000)];
    [label setStringValue:text];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setDrawsBackground:NO];
    [label setTextColor:GetRGBColor(0xe0e0e0, 1.0)];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label sizeToFit];
    [label setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

    NSRect labelFrame = [label frame];

    [container setFrame:NSInsetRect(labelFrame, -16, -16)];
    labelFrame.origin = NSMakePoint(16, 16);
    [label setFrame:labelFrame];
    [container addSubview:label];
    
    NSViewController *vc = [[NSViewController alloc] init];
    [vc setView:container];

    [popover setContentViewController:vc];
    
    [popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}


@end
