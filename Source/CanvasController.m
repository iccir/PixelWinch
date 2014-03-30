//
//  DocumentController.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "CanvasController.h"

#import "BlackSegmentedControl.h"

#import "Library.h"
#import "LibraryItem.h"
#import "Screenshot.h"

#import "BlackScroller.h"

#import "ShadowView.h"
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
#import "ShroudView.h"
#import "CanvasWindow.h"


#if ENABLE_APP_STORE
#import "ReceiptValidation_C.h"
#else
#import "Expiration.h"
#endif


#define sCheckAndProtect _
static inline __attribute__((always_inline)) void sCheckAndProtect()
{
#if ENABLE_APP_STORE
    if (![[PurchaseManager sharedInstance] doesReceiptExist]) {
        exit(173);
    }
#else
    __block long long expiration = kExpirationLong;

    ^{
        if (CFAbsoluteTimeGetCurrent() > expiration) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
                int *zero = (int *)(long)(rand() >> 31);
                *zero = 0;
            });
        }
    }();
#endif
}


#import "CursorAdditions.h"

@interface CanvasController () <
    CanvasWindowDelegate,
    ShroudViewDelegate,
    CanvasDelegate,
    CanvasViewDelegate,
    RulerViewDelegate,
    ToolOwner
>

@end


@implementation CanvasController {
    Toolbox    *_toolbox;

    ShadowView *_shadowView;

    ShroudView *_shroudView;
    NSView     *_transitionImageView;
    CGRect      _transitionImageGlobalRect;
    CGImageRef  _transitionImage;

    CGFloat     _liveMagnificationLevel;
    CGPoint     _liveMagnificationPoint;

    Canvas     *_canvas;
    ObjectEdge  _selectedEdge;
    
    LibraryItem *_currentLibraryItem;

    NSMutableDictionary *_GUIDToViewMap;
    NSMutableDictionary *_GUIDToResizeKnobsMap;
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

        for (Tool *tool in [_toolbox allTools]) {
            [tool setOwner:self];
        }

        [_toolbox addObserver:self forKeyPath:@"selectedTool" options:0 context:NULL];

        _library = [Library sharedInstance];
        
        _magnificationManager = [[MagnificationManager alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleApplicationDidResignActiveNotification:) name:NSApplicationDidResignActiveNotification object:nil];
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


- (void) keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar   c          = [characters length] ? [characters characterAtIndex:0] : 0;

    NSUInteger modifierFlags = [theEvent modifierFlags] & (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask);

    BOOL isArrowKey = (c == NSUpArrowFunctionKey ||
                       c == NSDownArrowFunctionKey ||
                       c == NSLeftArrowFunctionKey ||
                       c == NSRightArrowFunctionKey);
    
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
            NSString *guideGroupName = [Guide groupName];

            BOOL isHidden = [_canvas isGroupNameHidden:guideGroupName];
            [_canvas setGroupName:guideGroupName hidden:!isHidden];

            return;

        } else if (c == '-') {
            [_magnificationManager zoomOut];
            return;

        } else if (c == '=') {
            [_magnificationManager zoomIn];
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
            
        } else if (c == 'S') {
            // Save as? / Export?
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
    NSImage *arrowSelected     = [NSImage imageNamed:@"toolbar_arrow_selected"];
    NSImage *handSelected      = [NSImage imageNamed:@"toolbar_hand_selected"];
    NSImage *marqueeSelected   = [NSImage imageNamed:@"toolbar_marquee_selected"];
    NSImage *rectangleSelected = [NSImage imageNamed:@"toolbar_rectangle_selected"];
    NSImage *lineSelected      = [NSImage imageNamed:@"toolbar_line_selected"];
    NSImage *grappleSelected   = [NSImage imageNamed:@"toolbar_grapple_selected"];
    NSImage *zoomSelected      = [NSImage imageNamed:@"toolbar_zoom_selected"];

    [_toolPicker setSelectedImage:arrowSelected     forSegment:0];
    [_toolPicker setSelectedImage:handSelected      forSegment:1];
    [_toolPicker setSelectedImage:marqueeSelected   forSegment:2];
    [_toolPicker setSelectedImage:rectangleSelected forSegment:3];
    [_toolPicker setSelectedImage:lineSelected      forSegment:4];
    [_toolPicker setSelectedImage:grappleSelected   forSegment:5];
    [_toolPicker setSelectedImage:zoomSelected      forSegment:6];

    CanvasWindow *window = [[CanvasWindow alloc] initWithContentRect:CGRectMake(0, 0, 640, 400) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

    XUIView *contentView = [[XUIView alloc] initWithFrame:[[window contentView] frame]];
    [contentView setFlipped:NO];

    [window setContentView:contentView];
    [window setRestorable:NO];

    [_horizontalRuler setCanDrawConcurrently:YES];
    [_horizontalRuler setVertical:NO];
    
    [_verticalRuler setCanDrawConcurrently:YES];
    [_verticalRuler setVertical:YES];
    
    [_magnificationManager setHorizontalRuler:_horizontalRuler];
    [_magnificationManager setVerticalRuler:_verticalRuler];
    
    _shroudView = [[ShroudView alloc] initWithFrame:[contentView bounds]];
    [_shroudView setBackgroundColor:[NSColor colorWithCalibratedWhite:0 alpha:0.5]];
    [_shroudView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [_shroudView setDelegate:self];
    
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
    
    [contentView addSubview:_shroudView];

    [_contentTopLevelView setWantsLayer:YES];
    [_contentTopLevelView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [_contentTopLevelView setBackgroundColor:darkColor];
    [_contentTopLevelView setCornerRadius:8];
    [_contentTopLevelView setDelegate:self];
    [_contentTopLevelView setClipsToBounds:YES];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowOffset:NSMakeSize(0, 4)];
    [shadow setShadowBlurRadius:16];

    _shadowView = [[ShadowView alloc] initWithFrame:[_contentTopLevelView frame]];
    [_shadowView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [_shadowView setBackgroundColor:darkColor];
    [_shadowView setCornerRadius:8];
    [_shadowView setShadow:shadow];

    [contentView addSubview:_shadowView];
    [contentView addSubview:_contentTopLevelView];

    [window setHasShadow:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setOpaque:NO];

    if (!IsInDebugger()) {
        [window setLevel:NSModalPanelWindowLevel-1];
    }

    [window setDelegate:self];
    
    [self                   addObserver:self forKeyPath:@"librarySelectionIndexes" options:0 context:NULL];
    [self                   addObserver:self forKeyPath:@"selectedObject"          options:0 context:NULL];
    [_libraryCollectionView addObserver:self forKeyPath:@"isFirstResponder"        options:0 context:NULL];

    [window setAutorecalculatesKeyViewLoop:YES];
    
    [self setWindow:window];

    [self _updateInspector];
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


- (void) _updateWindowForScreen:(NSScreen *)screen
{
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

    [_contentTopLevelView setFrame:contentRect];
    [_shadowView setFrame:contentRect];
}


- (void) _doOrderInAnimation
{
    NSDisableScreenUpdates();

    CGRect scrollRectInWindow = CGRectZero;
    if (_transitionImageView) {
        NSView *contentView = [[self window] contentView];

        [contentView addSubview:_transitionImageView];
        
        NSRect appKitRect = [NSScreen winch_convertRectFromGlobal:_transitionImageGlobalRect];
        
        CGRect frame = [[self window] convertRectFromScreen:appKitRect];
        frame = [contentView convertRect:frame fromView:nil];
        [_transitionImageView setFrame:frame];

        [_canvasScrollView tile];

        scrollRectInWindow = [_canvasView convertRect:[_canvasView bounds] toView:nil];
        
        [_canvasScrollView setHidden:YES];
    }

    [_shroudView setAlphaValue:0];
    [_contentTopLevelView setAlphaValue:0];
    [_shadowView setAlphaValue:0];

    [[self window] display];
    NSEnableScreenUpdates();

    CGSize size = [_contentTopLevelView bounds].size;

    __weak id weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.25];
        [[_shroudView animator] setAlphaValue:1.0];

        [[_contentTopLevelView animator] setAlphaValue:1.0];
        [[_shadowView          animator] setAlphaValue:1.0];

        if (_transitionImageView) {
            [[_transitionImageView animator] setFrame:scrollRectInWindow];
        }

    } completionHandler:^{
        NSDisableScreenUpdates();
        [_canvasScrollView setHidden:NO];

        for (Tool *tool in [_toolbox allTools]) {
            [tool canvasWindowDidAppear];
        }

        [weakSelf _removeTransitionImage];
        [[self window] display];
        NSEnableScreenUpdates();
    }];

    if (!_transitionImageView) {
        CGAffineTransform fromTransform = CGAffineTransformIdentity;
        fromTransform = CGAffineTransformTranslate(fromTransform, size.width / 4, size.height / 4);
        fromTransform = CGAffineTransformScale(fromTransform, 0.5, 0.5);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [animation setDuration:0.25];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [animation setFromValue:[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(fromTransform)]];
        [animation setToValue:  [NSValue valueWithCATransform3D:CATransform3DIdentity]];
        [animation setFillMode:kCAFillModeBoth];

        [[_contentTopLevelView layer] addAnimation:animation forKey:@"transform"];
        [[_shadowView          layer] addAnimation:animation forKey:@"transform"];
    }
}


- (void) _doOrderOutAnimation
{
    CGSize size = [_contentTopLevelView bounds].size;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.25];
        [[_shroudView          animator] setAlphaValue:0.0];
        [[_contentTopLevelView animator] setAlphaValue:0.0];
        [[_shadowView          animator] setAlphaValue:0.0];
    } completionHandler:^{
        [[self window] orderOut:self];
    }];

    CGAffineTransform fromTransform = CGAffineTransformIdentity;
    fromTransform = CGAffineTransformTranslate(fromTransform, size.width / 4, size.height / 4);
    fromTransform = CGAffineTransformScale(fromTransform, 0.5, 0.5);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    [animation setDuration:0.25];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [animation setFromValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]];
    [animation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(fromTransform)]];
    [animation setFillMode:kCAFillModeBoth];
    
    [[_contentTopLevelView layer] addAnimation:animation forKey:@"transform"];
    [[_shadowView          layer] addAnimation:animation forKey:@"transform"];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    for (CanvasObjectView *view in [_GUIDToViewMap allValues]) {
        [view preferencesDidChange:preferences];
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

// Disabled for now
//    } else if ([[self selectedObject] isKindOfClass:[Rectangle class]]) {
//        view = [self rectangleObjectView];
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


- (void) _removeTransitionImage
{
    CGImageRelease(_transitionImage);
    _transitionImage = NULL;
    
    [_transitionImageView removeFromSuperview];
    _transitionImageView = nil;

    _transitionImageGlobalRect = CGRectZero;
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


- (void) shroudView:(ShroudView *)shroudView clickedWithEvent:(NSEvent *)event
{
    if (shroudView == _shroudView) {
        [self hide];
    } else if (shroudView == _contentTopLevelView) {
        [[self window] makeFirstResponder:[self window]];
    }
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

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromGlobalRect:(CGRect)globalRect
{
    [self window];  // Force nib to load

    PreferredDisplay preferredDisplay = [[Preferences sharedInstance] preferredDisplay];

    BOOL useZoomAnimation = NO;

    NSScreen *preferredScreen = nil;
    if (preferredDisplay == PreferredDisplayMain) {
        preferredScreen = [[NSScreen screens] firstObject];
    } else if (preferredDisplay == PreferredDisplaySame) {
        preferredScreen = [NSScreen winch_screenWithGlobalRect:globalRect];
    } else {
        preferredScreen = [NSScreen winch_screenWithCGDirectDisplayID:preferredDisplay];
    }

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

    [self _removeTransitionImage];

    sCheckAndProtect();

    // Set up transition image if we can use the zoom animation
    if (useZoomAnimation) {
        CGImageRef image = [[libraryItem screenshot] CGImage];

        CGImageRelease(_transitionImage);
        _transitionImage = CGImageRetain(image);

        _transitionImageView = [[NSView alloc] initWithFrame:globalRect];
        [_transitionImageView setWantsLayer:YES];
        [[_transitionImageView layer] setMagnificationFilter:kCAFilterNearest];
        [[_transitionImageView layer] setContents:(__bridge id)_transitionImage];
        
        _transitionImageGlobalRect = globalRect;
    }

    NSDisableScreenUpdates();

    [self _updateWindowForScreen:preferredScreen];
    [self _updateCanvasWithLibraryItem:libraryItem];
    [self _doOrderInAnimation];

    [NSApp activateIgnoringOtherApps:YES];
    [[CursorInfo sharedInstance] setEnabled:YES];

    [[self window] makeKeyAndOrderFront:self];
    
    NSEnableScreenUpdates();

    [[self window] makeFirstResponder:[self window]];
}


- (void) toggleVisibility
{
    NSWindow *window = [self window];
    
    if ([window isVisible]) {
        [self hide];

    } else {
        [self _updateWindowForScreen:[NSScreen mainScreen]];

        [self _removeTransitionImage];

        if (!_currentLibraryItem) {
            LibraryItem *item = [[[Library sharedInstance] items] lastObject];
            if (!item) {
                NSBeep();
                return;
            }

            [self _updateCanvasWithLibraryItem:item];
        }

        [self _doOrderInAnimation];

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

    [self _doOrderOutAnimation];
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



@end
