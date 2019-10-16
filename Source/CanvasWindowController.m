//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "CanvasWindowController.h"

#import "Library.h"
#import "LibraryItem.h"
#import "Screenshot.h"

#import "CanvasView.h"
#import "RulerView.h"
#import "CenteringClipView.h"

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
#import "CanvasWindow.h"
#import "MeasurementLabel.h"

#import "CursorAdditions.h"


#if 0 && DEBUG
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...)
#endif


@interface CanvasWindowController () <
    NSToolbarDelegate,
    CanvasWindowDelegate,
    CanvasDelegate,
    CanvasViewDelegate,
    RulerViewDelegate,
    ToolOwner
>

@end


@implementation CanvasWindowController {
    NSWindow    *_canvasWindow;
    
    Toolbox     *_toolbox;
    
    CGFloat      _liveMagnificationLevel;
    CGPoint      _liveMagnificationPoint;

    Canvas      *_canvas;
    ObjectEdge   _selectedEdge;
    
    LibraryItem  *_currentLibraryItem;

    NSMutableDictionary *_GUIDToViewMap;
    NSMutableDictionary *_GUIDToResizeKnobsMap;
    
    NSRunningApplication *_applicationToReactivate;
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

    if ([_toolbox isInTemporaryMode]) {
        [_toolbox updateTemporaryMode];
    } else {
        [[_toolbox selectedTool] flagsChangedWithEvent:theEvent];
    }

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

    } else if (action == @selector(delete:) || action == @selector(cut:) || action == @selector(duplicate:)) {
        return [[_canvas selectedObjects] count] > 0;

    } else if (action == @selector(paste:)) {
        return [[NSPasteboard generalPasteboard] dataForType:PasteboardTypeCanvasObjects] != nil;

    } else if (action == @selector(exportItem:) ||
               action == @selector(zoomIn:)     ||
               action == @selector(zoomOut:)    ||
               action == @selector(zoomTo:)     ||
               action == @selector(zoomToFit:)  ||
               action == @selector(deleteSelectedLibraryItem:))
    {
        return _currentLibraryItem != nil;
    }

    return YES;
}


- (void) keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar   c          = [characters length] ? [characters characterAtIndex:0] : 0;

    NSUInteger modifierFlags = [theEvent modifierFlags] & (
        NSEventModifierFlagShift   |
        NSEventModifierFlagControl |
        NSEventModifierFlagOption  |
        NSEventModifierFlagCommand
    );

    BOOL isArrowKey = (c == NSUpArrowFunctionKey ||
                       c == NSDownArrowFunctionKey ||
                       c == NSLeftArrowFunctionKey ||
                       c == NSRightArrowFunctionKey);
    
    if (c == ' ') {
        if (![theEvent isARepeat]) {
            [_toolbox beginTemporaryMode];
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

    } else if (modifierFlags == NSEventModifierFlagCommand) {
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

        } else if (c == 'a') {
            [_canvas selectAllObjects];
            return;

        } else if (c == 'd') {
            [_canvas deselectAllObjects];
            return;

        } else if (c == 's') {
            [self exportItem:nil];
            return;

        } else if (c >= '1' && c <= '8') {
            NSInteger level = (c - '0');
            [_magnificationManager setMagnification:level];
            return;

        } else if (c == '0') {
            [self zoomToFit:self];
        
        } else if (isArrowKey) {
            if ([self _selectEdgeWithArrowKey:c]) {
                return;
            }
        }

    } else if (modifierFlags == (NSEventModifierFlagCommand | NSEventModifierFlagShift)) {
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

        } else if (c == 'D') {
            [self duplicate:self];
            return;
        }

    } else if (modifierFlags == NSEventModifierFlagShift) {
        if (isArrowKey) {
            if ([self _moveSelectionWithArrowKey:c delta:10]) {
                return;
            }
            
        } else if (c == 'S') {
            [self exportItem:self];

        } else if (c == 'G') {
            GrappleTool *grappleTool = [_toolbox grappleTool];
            
            if ([[_toolbox selectedTool] isEqual:grappleTool]) {
                [grappleTool toggleVertical];
            } else {
                [_toolbox setSelectedToolName:[grappleTool name]];
            }

            return;
        }

    } else if (modifierFlags == (NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl)) {
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
        [_toolbox endTemporaryMode];
        return;
    }

    [super keyUp:theEvent];
}


- (void) magnifyWithEvent:(NSEvent *)event
{
    NSEventPhase phase = [event phase];
    
    if ((phase & NSEventPhaseChanged) > 0) {
        if (!isnan(_liveMagnificationLevel)) {
            _liveMagnificationLevel *= ([event magnification] + 1);
            
            NSArray *levels = [_magnificationManager levelsForSlider];
            NSInteger index = [_magnificationManager indexInArray:levels forMagnification:_liveMagnificationLevel];
            
            CGFloat level = [[levels objectAtIndex:index] doubleValue];

            [_canvasView setMagnification:level pinnedAtCanvasPoint:_liveMagnificationPoint];
            [_magnificationManager setMagnification:level];
        }

    } else if ((phase & NSEventPhaseBegan) > 0) {
        CGPoint canvasPoint = [_canvasView canvasPointForEvent:event];
        CGSize  canvasSize  = [_canvas size];

        if (canvasPoint.x >= 0 &&
            canvasPoint.y >= 0 &&
            canvasPoint.x < canvasSize.width &&
            canvasPoint.y < canvasSize.height)
        {
            _liveMagnificationLevel = [_magnificationManager magnification];
            _liveMagnificationPoint = canvasPoint;
        }
    }
}

- (void) windowDidLoad
{
    if ([[[Preferences sharedInstance] customScaleMultiplier] doubleValue]) {
        [_scalePicker setSegmentCount:4];

        NSImage *scaleCxImage = [NSImage imageNamed:@"ToolbarCx"];
        [_scalePicker setImage:scaleCxImage forSegment:3];
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
    [[_libraryScrollView horizontalScroller] setControlSize:NSControlSizeSmall];
    
    [_libraryCollectionView setBackgroundColors:@[ darkColor ]];
        
    [self                   addObserver:self forKeyPath:@"librarySelectionIndexes" options:0 context:NULL];
    [self                   addObserver:self forKeyPath:@"selectedObject"          options:0 context:NULL];
    [_libraryCollectionView addObserver:self forKeyPath:@"isFirstResponder"        options:0 context:NULL];
    [[_toolbox grappleTool] addObserver:self forKeyPath:@"vertical"                options:0 context:NULL];

    [self _updateCanvasWindow];

    [self _updateInspector];
    [self _updateGrappleIcon];
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
                    [_canvas deselectObject:selectedObject];
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

    } else if (object == [_toolbox grappleTool]) {
        if ([keyPath isEqualToString:@"vertical"]) {
            [self _updateGrappleIcon];
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

- (void) _updateCanvasWindow
{
    NSRect oldContentRect = CGRectMake(0, 0, 640, 400);

    if (_canvasWindow) {
        oldContentRect = [_canvasWindow contentRectForFrameRect:[_canvasWindow frame]];
        [_canvasWindow setDelegate:nil];
        [_canvasWindow orderOut:nil];
        _canvasWindow = nil;
    }

    NSUInteger canvasStyleMask = NSWindowStyleMaskBorderless;
    
    canvasStyleMask |= NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskFullSizeContentView;

    CanvasWindow *window = [[CanvasWindow alloc] initWithContentRect:oldContentRect styleMask:canvasStyleMask backing:NSBackingStoreBuffered defer:NO];

    BaseView *windowContentView = [[BaseView alloc] initWithFrame:[[window contentView] frame]];
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
    
        buildTopView(NSEdgeInsetsMake(7, 0, 6, 0), 8);

        [window setHasShadow:YES];

        [window setTitlebarAppearsTransparent:NO];
        [window setTitleVisibility:NSWindowTitleHidden];

        [window setBackgroundColor:[_canvasScrollView backgroundColor]];

        [window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];

        [window setContentMinSize:NSMakeSize(780, 320)];
        
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

        [window setFrameAutosaveName:@"CanvasWindow"];

        [windowContentView addSubview:_bottomView];
        [_bottomView setFrame:[window contentLayoutRect]];
    
    [self setWindow:window];

    _canvasWindow = window;
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    for (CanvasObjectView *view in [_GUIDToViewMap allValues]) {
        [view preferencesDidChange:preferences];
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


- (void) _updateGrappleIcon
{
    NSString *name = [[_toolbox grappleTool] isVertical] ? @"ToolbarGrapple" : @"ToolbarGrappleHorizontal";
    NSImage *grappleImage = [NSImage imageNamed:name];

    [[self touchBarToolPicker] setImage:grappleImage forSegment:5];
    [[self toolPicker] setImage:grappleImage forSegment:5];
}


- (void) _updateCanvasWithLibraryItem:(LibraryItem *)item
{
    Screenshot *screenshot = [item screenshot];

    if (_currentLibraryItem) {
        NSPoint scrollOrigin  = [_canvasScrollView documentVisibleRect].origin;
        CGFloat magnification = [_magnificationManager magnification];

        [_currentLibraryItem setMagnification:magnification];
        [_currentLibraryItem setScrollOrigin:scrollOrigin];
    }

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
    if ([_currentLibraryItem magnification]) {
        [_magnificationManager setMagnification:[_currentLibraryItem magnification]];
        
        [[_canvasScrollView contentView] scrollToPoint:[_currentLibraryItem scrollOrigin]];
        [_canvasScrollView reflectScrolledClipView:[_canvasScrollView contentView]];
        
    } else { 
        [self zoomToFit:self];

    }

    _liveMagnificationLevel = NAN;
}


- (void) _writeCanvasRect:(CGRect)rect toPasteboard:(NSPasteboard *)pasteboard
{
    NSImage *image = [_canvasView snapshotImageWithCanvasRect:rect];

    if (image) {
        [pasteboard clearContents];
        [pasteboard writeObjects:@[ image ] ];

    } else {
        NSBeep();
    }
}


#pragma mark - Selection

- (BOOL) _deleteSelectedObjects
{
    NSArray   *selectedObjects = [_canvas selectedObjects];
    NSUInteger count           = [selectedObjects count];

    if (count > 0) {
        if (count > 1) {
            [[_canvas undoManager] beginUndoGrouping];

            for (CanvasObject *selectedObject in selectedObjects) {
                [_canvas removeCanvasObject:selectedObject];
            }

            [[_canvas undoManager] endUndoGrouping];

        } else {
            [_canvas removeCanvasObject:[selectedObjects lastObject]];
        }

        return YES;
    }
    
    return NO;
}


- (BOOL) _moveSelectionWithArrowKey:(unichar)key delta:(CGFloat)inDelta
{
    NSArray *selectedObjects = [_canvas selectedObjects];
    BOOL didMove = NO;

    for (CanvasObject *selectedObject in selectedObjects) {
        CGFloat delta = inDelta;
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
        
                // Fade out resize knob during a move for lines
                //
                if ([selectedObject isKindOfClass:[Line class]] && _selectedEdge) {
                    NSArray *resizeKnobs = [_GUIDToResizeKnobsMap objectForKey:[selectedObject GUID]];
                 
                    for (ResizeKnobView *knob in resizeKnobs) {
                        if ([knob edge] == _selectedEdge) {
                            [knob hideMomentarily];
                        }
                    }
                }
        
                [selectedObject setRect:rect];
            }

            didMove = YES;
        }
    }

    return didMove;
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
    ObjectEdge newSelectedEdge = ObjectEdgeNone;
    
    for (CanvasObject *selectedObject in [_canvas selectedObjects]) {
        ObjectEdge edgeForThisObject = ObjectEdgeNone;
    
        if ([selectedObject isKindOfClass:[Rectangle class]]) {
            edgeForThisObject = [self _edgeOfRectangleByApplyingArrowKey:key toEdge:_selectedEdge];

        } else if ([selectedObject isKindOfClass:[Line class]]) {
            Line *line = (Line *)selectedObject;

            if ([line isVertical]) {
                if (key == NSUpArrowFunctionKey) {
                    edgeForThisObject = ObjectEdgeTop;
                } else if (key == NSDownArrowFunctionKey) {
                    edgeForThisObject = ObjectEdgeBottom;
                }
                
            } else {
                if (key == NSLeftArrowFunctionKey) {
                    edgeForThisObject = ObjectEdgeLeft;
                } else if (key == NSRightArrowFunctionKey) {
                    edgeForThisObject = ObjectEdgeRight;
                }
            }
        }
        
        if (edgeForThisObject == ObjectEdgeNone) {
            return NO;
        }
        
        newSelectedEdge = edgeForThisObject;
    }

    if (newSelectedEdge == ObjectEdgeNone) {
        return NO;
    }

    [self _updateSelectedEdge:newSelectedEdge];
    
    return YES;
}


- (void) _updateSelectedEdge:(ObjectEdge)edge
{
    _selectedEdge = edge;
    
    for (CanvasObject *selectedObject in [_canvas selectedObjects]) {
        NSArray *resizeKnobs = [_GUIDToResizeKnobsMap objectForKey:[selectedObject GUID]];
     
        for (ResizeKnobView *knob in resizeKnobs) {
            if ([knob edge] == _selectedEdge) {
                [knob setHighlighted:[[[knob owningObjectView] canvasObject] isEqual:selectedObject]];
            } else {
                [knob setHighlighted:NO];
            }
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
    
    [[_canvasView measurementLabelWithGUID:GUID] setSelected:YES];

    [self _updateSelectedEdge:ObjectEdgeNone];
}


- (void) canvas:(Canvas *)canvas didDeselectObject:(CanvasObject *)object
{
    NSString *GUID = [object GUID];
    NSArray  *resizeKnobs = [_GUIDToResizeKnobsMap objectForKey:GUID];
 
    [[_canvasView measurementLabelWithGUID:GUID] setSelected:NO];
    [self _updateSelectedEdge:ObjectEdgeNone];
    
    for (ResizeKnobView *knob in resizeKnobs) {
        [knob setOwningObjectView:nil];
        [_canvasView removeCanvasObjectView:knob];
    }

    [_GUIDToResizeKnobsMap removeObjectForKey:GUID];
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

        [_canvas deselectAllObjects];
        [_canvas selectObject:object];
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
        [_canvas deselectAllObjects];
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
        NSArray *selectedObjects = [_canvas selectedObjects];
        NSEventModifierFlags flags = [[NSApp currentEvent] modifierFlags];

        if ((flags & (NSEventModifierFlagShift|NSEventModifierFlagCommand)) > 0) {
            if ([selectedObjects containsObject:canvasObject]) {
                [_canvas deselectObject:canvasObject];
            } else {
                [_canvas selectObject:canvasObject];
            }
        
        } else if (![selectedObjects containsObject:canvasObject]) {
            [_canvas deselectAllObjects];
            [_canvas selectObject:canvasObject];
        }
    }

    for (CanvasObject *selectedObject in [_canvas selectedObjects]) {
        [selectedObject prepareRelativeMove];
    }
}


- (void) canvasView:(CanvasView *)view didTrackObjectView:(CanvasObjectView *)objectView
{

}


- (NSCursor *) cursorForCanvasView:(CanvasView *)view
{
    return [[_toolbox selectedTool] cursor];
}


- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event
{
    [[_toolbox selectedTool] mouseMovedWithEvent:event];
}


- (void) canvasView:(CanvasView *)view flagsChangedWithEvent:(NSEvent *)event
{
    [[_toolbox selectedTool] flagsChangedWithEvent:event];
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
    [result setMinSize:NSMakeSize(630,  40)];
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
        [_canvas deselectAllObjects];

    } else if (useEscapeToClose) {
        [self hide];
    }

    return YES;
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


- (void) windowDidResignKey:(NSNotification *)notification
{
    [[_toolbox selectedTool] canvasWindowDidResign];
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
        [self _updateCanvasWithLibraryItem:itemToOpen];
        [self activateAndShowWindow];

        return YES;
    }

    return NO;
}


- (BOOL) importImagesWithPasteboard:(NSPasteboard *)pasteboard
{
    NSData *data = nil;
    
    if (!data) data = [pasteboard dataForType:NSPasteboardTypePNG];
    if (!data) data = [pasteboard dataForType:NSPasteboardTypeTIFF];

    if (!data) {
        data = [[[pasteboard readObjectsForClasses:@[ [NSImage class] ] options:nil] firstObject] TIFFRepresentation];
    }
    
    LibraryItem *item = nil;
    
    if (data) {
        item = [[Library sharedInstance] importedItemWithData:data];
    }

    if (item) {
        [self _updateCanvasWithLibraryItem:item];
        [self activateAndShowWindow];

        return YES;
    }

    return NO;
}



- (void) presentLibraryItem:(LibraryItem *)libraryItem
{
    [self window];  // Force nib to load

    [self _updateCanvasWithLibraryItem:libraryItem];

    NSView *viewToBlock = _bottomView;

    BaseView *blockerView = [[BaseView alloc] initWithFrame:[viewToBlock bounds]];
    [blockerView setBackgroundColor:[NSColor clearColor]];
     {
        // Overlay animation can hide the scroll view, be paranoid if we changed modes
        [_canvasScrollView setHidden:NO];
    }
    
    [NSApp activateIgnoringOtherApps:YES];
    [[CursorInfo sharedInstance] setEnabled:YES];

    [[self window] makeKeyAndOrderFront:self];
    
    [[self window] makeFirstResponder:[self window]];
}


- (void) activateAndShowWindow
{
    if ([self isWindowVisible]) {
        [NSApp activateIgnoringOtherApps:YES];
        [[self window] makeKeyAndOrderFront:nil];

    } else {
        [self toggleVisibility];
    }
}


- (void) performToggleWindowShortcut
{
    if ([self isWindowVisible]) {
        [self hide];

        if (_applicationToReactivate) {
            [_applicationToReactivate activateWithOptions:NSApplicationActivateIgnoringOtherApps];
            _applicationToReactivate = nil;
        }

    } else {
        [self toggleVisibility];
    }
}


- (void) toggleVisibility
{
    if ([self isWindowVisible]) {
        [self hide];

    } else {
        if (!_currentLibraryItem) {
            LibraryItem *item = [[[Library sharedInstance] items] lastObject];
            if (!item) {
                NSBeep();
                return;
            }

            [self _updateCanvasWithLibraryItem:item];
        }

        _applicationToReactivate = [[NSWorkspace sharedWorkspace] frontmostApplication];

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
    [Screenshot clearCache];
    
    [[self window] orderOut:self];
}


- (BOOL) isWindowVisible
{
    if (([[self window] occlusionState] & NSWindowOcclusionStateVisible) == 0) {
        return NO;
    }

    return [[self window] isVisible];
}


- (IBAction) copy:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];

    if ([_toolbox selectedTool] == [_toolbox marqueeTool]) {
        Marquee *lastMarquee = [[_canvas canvasObjectsWithGroupName:[Marquee groupName]] lastObject];
        [self _writeCanvasRect:[lastMarquee rect] toPasteboard:[NSPasteboard generalPasteboard]];
        return;
    }

    NSArray *selectedObjects = [_canvas selectedObjects];
    if ([selectedObjects count]) {
        NSMutableArray *lines = [NSMutableArray array];
        
        for (CanvasObject *selectedObject in selectedObjects) {
            NSString *line = [selectedObject pasteboardString];
            if ([line length]) [lines addObject:line];
        }

        [pboard clearContents];
        [pboard setString:[lines componentsJoinedByString:@"\n"] forType:NSPasteboardTypeString];
        
        NSData *data = [CanvasObject pasteboardDataWithCanvasObjects:selectedObjects];
        if (data) [pboard setData:data forType:PasteboardTypeCanvasObjects];

    } else {
        CGSize size = [[_currentLibraryItem screenshot] size];
        CGRect rect = { CGPointZero, size };

        [self _writeCanvasRect:rect toPasteboard:[NSPasteboard generalPasteboard]];
    }
}


- (void) delete:(id)sender
{
    [self _deleteSelectedObjects];
}


- (IBAction) cut:(id)sender
{
    [self copy:sender];
    [self delete:sender];

    [[self undoManager] setActionName:NSLocalizedString(@"Cut", nil)];
}


- (IBAction) paste:(id)sender
{
    NSData *data = [[NSPasteboard generalPasteboard] dataForType:PasteboardTypeCanvasObjects];
    if (!data) return;

    NSArray *objects = [CanvasObject canvasObjectsWithPasteboardData:data];
    
    for (CanvasObject *object in objects) {
        [_canvas addCanvasObject:object];
    }

    [_canvas deselectAllObjects];
    for (CanvasObject *object in objects) {
        [_canvas selectObject:object];
    }
}

- (IBAction) selectAll:(id)sender
{
    [_canvas selectAllObjects];
}


- (IBAction) deselectAll:(id)sender
{
    [_canvas deselectAllObjects];
}


- (IBAction) duplicate:(id)Sender
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
        [_canvas deselectAllObjects];
        [_canvas selectObject:lastDuplicate];
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
    NSIndexSet *selected   = _librarySelectionIndexes;
    NSArray    *items      = [[Library sharedInstance] items];
    NSUInteger  itemsCount = [items count];

    NSUInteger selectedIndex = [selected lastIndex];

    if (itemsCount == 0 || selectedIndex == NSNotFound) {
        return;
    }

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


- (IBAction) zoomToFit:(id)sender
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
    if (!_currentLibraryItem) return;

    NSSavePanel *savePanel = [NSSavePanel savePanel];

    [savePanel setNameFieldStringValue:@"Pixel Winch Image"];
    [savePanel setShowsTagField:NO];
    [savePanel setAllowedFileTypes:@[ @"public.png" ]];
    
    if ([savePanel runModal] == NSModalResponseOK) {
        CGSize size = [[_currentLibraryItem screenshot] size];
        CGRect rect = { CGPointZero, size };

        NSImage *snapshot = [_canvasView snapshotImageWithCanvasRect:rect];
       
        NSDictionary *properties = [NSDictionary dictionary];
        
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[snapshot TIFFRepresentation]];
        NSData *data = [rep representationUsingType:NSBitmapImageFileTypePNG properties:properties];
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
    
    NSAppearance *popoverAppearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    [popover setAppearance:popoverAppearance];
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
