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

#import "Toolbox.h"
#import "Tool.h"
#import "MoveTool.h"
#import "HandTool.h"
#import "MarqueeTool.h"
#import "RectangleTool.h"
#import "GrappleTool.h"
#import "ZoomTool.h"

#import "Canvas.h"
#import "Guide.h"
#import "Grapple.h"
#import "Rectangle.h"
#import "Marquee.h"

#import "GuideObjectView.h"
#import "GrappleObjectView.h"
#import "RectangleObjectView.h"
#import "MarqueeObjectView.h"
#import "ResizeKnobView.h"
#import "ShroudView.h"
#import "CanvasWindow.h"


#import "GrappleCalculator.h"

#import "CursorAdditions.h"

@interface CanvasController () <CanvasWindowDelegate, ShroudViewDelegate, CanvasDelegate, CanvasViewDelegate, RulerViewDelegate>
@end


@implementation CanvasController {
    Toolbox    *_toolbox;

    ShadowView *_shadowView;

    ShroudView *_shroudView;
    NSView     *_transitionImageView;
    CGRect      _transitionImageRect;
    CGImageRef  _transitionImage;

    NSEvent *_zoomEvent;
    NSPoint  _handEventStartPoint;
    NSPoint  _handCanvasStartPoint;

    CGPoint _lastPreviewGrapplePoint;

    Canvas  *_canvas;
    LibraryItem *_selectedItem;
    NSMutableDictionary *_GUIDToLayerMap;
    
    CanvasObject   *_selectedObject;
    NSMutableArray *_selectionLayers;
}


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        _GUIDToLayerMap = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];

        _toolbox = [[Toolbox alloc] init];

        [_toolbox            addObserver:self forKeyPath:@"selectedTool"       options:0 context:NULL];
        [[_toolbox zoomTool] addObserver:self forKeyPath:@"magnificationLevel" options:0 context:NULL];

        _library = [Library sharedInstance];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleApplicationDidResignActiveNotification:) name:NSApplicationDidResignActiveNotification object:nil];
    }
    
    return self;
}


- (void) dealloc
{
    [_toolbox            removeObserver:self forKeyPath:@"selectedTool"       context:NULL];
    [[_toolbox zoomTool] removeObserver:self forKeyPath:@"magnificationLevel" context:NULL];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) flagsChanged:(NSEvent *)theEvent
{
    [_canvasView invalidateCursors];
    [self _updatePreviewGrapple];
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
        if (c == 'z') {
            [_toolbox setSelectedToolType:ToolTypeZoom];
            return;

        } else if (c == 'h') {
            [_toolbox setSelectedToolType:ToolTypeHand];
            return;
        
        } else if (c == 'm') {
            [_toolbox setSelectedToolType:ToolTypeMarquee];
            return;
        
        } else if (c == 'v') {
            [_toolbox setSelectedToolType:ToolTypeMove];
            return;

        } else if (c == 'r') {
            [_toolbox setSelectedToolType:ToolTypeRectangle];
            return;

        } else if (c == 'g') {
            [_toolbox setSelectedToolType:ToolTypeGrapple];
            return;

        } else if (c == NSDeleteCharacter || c == NSBackspaceCharacter) {
            if ([self _deleteSelectedObjects]) return;

        } else if (isArrowKey) {
            if ([self _moveSelectedObjectWithArrowKey:c delta:1]) {
                return;
            }
        }

    } else if (modifierFlags == NSCommandKeyMask) {
        if (c == NSDeleteCharacter || c == NSBackspaceCharacter) {
            // Delete current screenshot

        } else if (c == 'w') {
            [self hide];
            return;

        } else  if (c == ';') {
            // Toggle guides
            return;

        } else if (c == '-') {
            [[_toolbox zoomTool] zoomOut];
            return;

        } else if (c == '+') {
            [[_toolbox zoomTool] zoomIn];
            return;

        } else if (c >= '1' && c <= '8') {
            NSInteger level = (c - '0');
            [[_toolbox zoomTool] zoomToMagnificationLevel:level];
            return;
        }

    } else if (modifierFlags == (NSCommandKeyMask | NSShiftKeyMask)) {
        if (c == '{') {
            // Select previous screenshot
            return;

        } else if (c == '}') {
            // Select next screenshot
            return;
            
        } else if (c == 'S') {
            // Save as? / Export?
            return;
        }

    } else if (modifierFlags == NSShiftKeyMask) {
        if (isArrowKey) {
            if ([self _moveSelectedObjectWithArrowKey:c delta:10]) {
                return;
            }
        }

    } else if (modifierFlags == (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask)) {
        if (c == 'r') {
            [self _debugResponderChain];
            return;

        } else if (c == 'a') {
            [[NSWorkspace sharedWorkspace] openFile:GetApplicationSupportDirectory()];
            return;
        }
    }

    [super keyDown:theEvent];
}


- (void) awakeFromNib
{
    NSImage *arrowSelected     = [NSImage imageNamed:@"toolbar_arrow_selected"];
    NSImage *handSelected      = [NSImage imageNamed:@"toolbar_hand_selected"];
    NSImage *marqueeSelected   = [NSImage imageNamed:@"toolbar_marquee_selected"];
    NSImage *rectangleSelected = [NSImage imageNamed:@"toolbar_rectangle_selected"];
    NSImage *grappleSelected   = [NSImage imageNamed:@"toolbar_grapple_selected"];
    NSImage *zoomSelected      = [NSImage imageNamed:@"toolbar_zoom_selected"];

    [_toolPicker setSelectedImage:arrowSelected     forSegment:0];
    [_toolPicker setSelectedImage:handSelected      forSegment:1];
    [_toolPicker setSelectedImage:marqueeSelected   forSegment:2];
    [_toolPicker setSelectedImage:rectangleSelected forSegment:3];
    [_toolPicker setSelectedImage:grappleSelected   forSegment:4];
    [_toolPicker setSelectedImage:zoomSelected      forSegment:5];

    CanvasWindow *window = [[CanvasWindow alloc] initWithContentRect:CGRectMake(0, 0, 640, 400) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

    XUIView *contentView = [[XUIView alloc] initWithFrame:[[window contentView] frame]];
    [contentView setFlipped:NO];

    [window setContentView:contentView];

    [_horizontalRuler setCanDrawConcurrently:YES];
    [_horizontalRuler setVertical:NO];
    
    [_verticalRuler setCanDrawConcurrently:YES];
    [_verticalRuler setVertical:YES];
    
    _shroudView = [[ShroudView alloc] initWithFrame:[contentView bounds]];
    [_shroudView setBackgroundColor:[NSColor colorWithCalibratedWhite:0 alpha:0.45]];
    [_shroudView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [_shroudView setDelegate:self];
    
    NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];

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

    [window setLevel:NSScreenSaverWindowLevel];

    [window setDelegate:self];
    
    [self addObserver:self forKeyPath:@"librarySelectionIndexes" options:0 context:NULL];
    [_libraryCollectionView addObserver:self forKeyPath:@"isFirstResponder" options:0 context:NULL];
    
    [self setWindow:window];
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
        result = [[NSScreen screens] firstObject];
    }

    return result;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _toolbox) {
        if ([keyPath isEqualToString:@"selectedTool"]) {
            [self _updatePreviewGrapple];
            [self _updateInspector];
            
            ToolType selectedToolType = [_toolbox selectedToolType];
            
            [_canvas setMarqueeHidden:(selectedToolType != ToolTypeMarquee)];

            if ([_selectedObject isKindOfClass:[Rectangle class]]) {
                if ((selectedToolType != ToolTypeMove) && (selectedToolType != ToolTypeRectangle)) {
                    [self _unselectAllObjects];
                }

            } else if ([_selectedObject isKindOfClass:[Grapple class]]) {
                if ((selectedToolType != ToolTypeMove) && (selectedToolType != ToolTypeGrapple)) {
                    [self _unselectAllObjects];
                }
            }

            [_canvasView invalidateCursors];
        }

    } else if (object == [_toolbox zoomTool]) {
        if ([keyPath isEqualToString:@"magnificationLevel"]) {
            CGFloat magnification = [[_toolbox zoomTool] magnificationLevel];

            [_horizontalRuler setMagnification:magnification];
            [_verticalRuler   setMagnification:magnification];
            [_canvasView      setMagnification:magnification];

            if (_zoomEvent) {
                CGRect clipViewFrame = [[_canvasScrollView contentView] frame];
                CGPoint zoomPoint = [_canvasView canvasPointForEvent:_zoomEvent horizontalSnappingPolicy:SnappingPolicyNone verticalSnappingPolicy:SnappingPolicyNone];

                zoomPoint.x *= magnification;
                zoomPoint.y *= magnification;

                zoomPoint.x -= NSWidth( clipViewFrame) / 2.0;
                zoomPoint.y -= NSHeight(clipViewFrame) / 2.0;
                
                [[_canvasScrollView documentView] scrollPoint:zoomPoint];

                _zoomEvent = nil;
            }
        }

    } else if (object == self) {
        if ([keyPath isEqualToString:@"librarySelectionIndexes"]) {
            LibraryItem *item = [[_libraryArrayController selectedObjects] lastObject];

            if (item != _selectedItem) {
                [self _updateCanvasWithLibraryItem:item];
            }
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
    
    CGRect contentRect = CGRectInset(entireFrame, leftRight + 16, topBottom + 16);
    
    [[self window] setFrame:entireFrame display:NO];
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
        
        CGRect frame = [[self window] convertRectFromScreen:_transitionImageRect];
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

    for (CanvasObjectView *view in [_GUIDToLayerMap allValues]) {
        [view preferencesDidChange:preferences];
    }
}


- (CanvasObjectView *) _viewForCanvasObject:(CanvasObject *)object
{
    if (!object) return nil;
    return [_GUIDToLayerMap objectForKey:[object GUID]];
}


- (void) _handleApplicationDidResignActiveNotification:(NSNotification *)note
{
    [self hide];
}


- (void) _updateInspector
{
    ToolType type = [[_toolbox selectedTool] type];
    NSView *view = nil;

    if (type == ToolTypeZoom) {
        view = [self zoomToolView];
    } else if (type == ToolTypeGrapple) {
        view = [self grappleToolView];
    } else if ([_selectedObject isKindOfClass:[Rectangle class]]) {
        view = [self rectangleObjectView];
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


- (void) _removePreviewGrapple
{
    [[CursorInfo sharedInstance] setText:nil forKey:@"preview-grapple"];
    [_canvas removePreviewGrapple];
}


- (void) _removeTransitionImage
{
    CGImageRelease(_transitionImage);
    _transitionImage = NULL;
    
    [_transitionImageView removeFromSuperview];
    _transitionImageView = nil;

    _transitionImageRect = CGRectZero;
}


- (void) _updateCanvasWithLibraryItem:(LibraryItem *)item
{
    Screenshot *screenshot = [item screenshot];

    // Step two, update canvas if needed
    if ([_canvas screenshot] != screenshot) {

        [self _unselectAllObjects];
        _lastPreviewGrapplePoint = CGPointMake(NAN, NAN);
        
        _GUIDToLayerMap = [NSMutableDictionary dictionary];

        // Write out current canvas to disk
        if (_selectedItem && _canvas) {
            [_selectedItem setCanvasDictionary:[_canvas dictionaryRepresentation]];
        }
        
        Canvas *canvas = [[Canvas alloc] initWithDelegate:self];
        _canvas = canvas;
        _selectedItem = item;
        if (_selectedItem) {
            [_libraryArrayController setSelectedObjects:@[ _selectedItem ] ];
        } else {
            [_libraryArrayController setSelectedObjects:@[ ]];
        }

        if (canvas) {
            CanvasView *canvasView = [[CanvasView alloc] initWithFrame:CGRectZero canvas:canvas];
            [canvasView setDelegate:self];
            _canvasView = canvasView;

            [_canvasScrollView setDocumentView:canvasView];
        } else {
            _canvasView = nil;
            [_canvasScrollView setDocumentView:[[NSView alloc] init]];
        }
        
        [canvas setupWithScreenshot:screenshot dictionary:[item canvasDictionary]];

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
        
        NSInteger index = [[_toolbox zoomTool] magnificationIndexForLevel:(xScale < yScale ? xScale : yScale)];
        
        [[_toolbox zoomTool] setMagnificationIndex:index];
    }
}


- (void) _updatePreviewGrapple
{
    if (([_toolbox selectedToolType] != ToolTypeGrapple) || isnan(_lastPreviewGrapplePoint.x)) {
        [self _removePreviewGrapple];
        return;
    }
    
    GrappleTool *grappleTool = [_toolbox grappleTool];
    BOOL isVertical = [grappleTool calculatedIsVertical];

    if ([[_canvas previewGrapple] isVertical] != isVertical) {
        [self _removePreviewGrapple];
    }

    if (![_canvas previewGrapple]) {
        [_canvas makePreviewGrappleVertical:isVertical];
    }
    
    Grapple *previewGrapple = [_canvas previewGrapple];
    CGPoint point = _lastPreviewGrapplePoint;
    [_canvas updateGrapple:previewGrapple point:point threshold:[grappleTool calculatedThreshold]];

    if (![previewGrapple length]) {
        [self _removePreviewGrapple];
        return;
    }

    NSString *previewText = GetStringForFloat([previewGrapple length]);
    [[CursorInfo sharedInstance] setText:previewText forKey:@"preview-grapple"];
}


#pragma mark - Selection

- (void) _selectObject:(CanvasObject *)object
{
    [self _unselectAllObjects];

    if (!_selectionLayers) {
        _selectionLayers = [NSMutableArray array];
    }
    
    void (^addResizeKnob)(CanvasObjectView *, ResizeKnobType) = ^(CanvasObjectView *parent, ResizeKnobType knobType) {
        ResizeKnobView *knob = [[ResizeKnobView alloc] initWithFrame:NSZeroRect];
        
        [knob setType:knobType];
        [knob setCanvasObjectView:parent];
    
        [_canvasView addCanvasObjectView:knob];
    
        [_selectionLayers addObject:knob];
    };

    CanvasObjectView *parentView = [self _viewForCanvasObject:object];
    NSArray *resizeKnobTypes = [parentView resizeKnobTypes];

    for (NSNumber *resizeKnobNumber in resizeKnobTypes) {
        addResizeKnob(parentView, [resizeKnobNumber integerValue]);
    }
    
    [self setSelectedObject:object];
}


- (void) _unselectAllObjects
{
    for (ResizeKnobView *knob in _selectionLayers) {
        [_canvasView removeCanvasObjectView:knob];
    }

    _selectionLayers = nil;
    
    [self setSelectedObject:nil];
    _selectedObject = nil;
}


- (BOOL) _deleteSelectedObjects
{
    CanvasObject *selectedObject = _selectedObject;
    
    if (selectedObject) {
        [_canvas removeObject:selectedObject];
        return YES;
    }
    
    return NO;
}


- (BOOL) _moveSelectedObjectWithArrowKey:(unichar)key delta:(CGFloat)delta
{
    CanvasObject *selectedObject = _selectedObject;

    if (selectedObject) {
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

        return YES;
    }
    
    return NO;
}


#pragma mark - Canvas Delegate

- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object
{
    CanvasObjectView *view = nil;

    if ([object isKindOfClass:[Guide class]]) {
        GuideObjectView *guideLayer = [[GuideObjectView alloc] initWithFrame:NSZeroRect];
        [guideLayer setGuide:(Guide *)object];
        view = guideLayer;

    } else if ([object isKindOfClass:[Grapple class]]) {
        GrappleObjectView *grappleLayer = [[GrappleObjectView alloc] initWithFrame:NSZeroRect];
        [grappleLayer setGrapple:(Grapple *)object];
        view = grappleLayer;

    } else if ([object isKindOfClass:[Rectangle class]]) {
        RectangleObjectView *rectangleLayer = [[RectangleObjectView alloc] initWithFrame:NSZeroRect];
        [rectangleLayer setRectangle:(Rectangle *)object];
        view = rectangleLayer;

    } else if ([object isKindOfClass:[Marquee class]]) {
        MarqueeObjectView *marqueeLayer = [[MarqueeObjectView alloc] initWithFrame:NSZeroRect];
        [marqueeLayer setMarquee:(Marquee *)object];
        view = marqueeLayer;
    }
    
    if (view) {
        [_GUIDToLayerMap setObject:view forKey:[object GUID]];
        [_canvasView addCanvasObjectView:view];
    }
}


- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object
{
    CanvasObjectView *layer = [self _viewForCanvasObject:object];

    if (layer) {
        [_canvasView updateCanvasObjectView:layer];
    }
}


- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object
{
    CanvasObjectView *view = [self _viewForCanvasObject:object];

    if (object == _selectedObject) {
        [self _unselectAllObjects];
    }
    
    if (view) {
        [_canvasView removeCanvasObjectView:view];
    }
}


#pragma mark - CanvasView Delegate

- (BOOL) canvasView:(CanvasView *)view shouldTrackObjectView:(CanvasObjectView *)objectView
{
    ToolType toolType = [_toolbox selectedToolType];

    // Guides are only clickable with Move tool
    //
    if ([objectView isKindOfClass:[GuideObjectView class]]) {
        return toolType == ToolTypeMove;

    // Marquees are only clickable with Marquee tool
    //
    } else if ([objectView isKindOfClass:[MarqueeObjectView class]]) {
        return toolType == ToolTypeMarquee;

    // Resize knobs are ALWAYS clickable unless tool is Zoom or Hand
    //
    } else if ([objectView isKindOfClass:[ResizeKnobView class]]) {
        return (toolType != ToolTypeHand) && (toolType != ToolTypeZoom);

    // Grapples are clickable in Grapple and Move, unless it's the preview grapple
    //
    } else if ([objectView isKindOfClass:[GrappleObjectView class]]) {
        if ([objectView canvasObject] == [_canvas previewGrapple]) {
            return NO;
        }
        
        return (toolType == ToolTypeMove) || (toolType == ToolTypeGrapple);

    // Rectangles are clickable in Rectangle and Move
    //
    } else if ([objectView isKindOfClass:[RectangleObjectView class]]) {
        return (toolType == ToolTypeMove) || (toolType == ToolTypeRectangle);
    }
    
    return NO;
}


- (void) canvasView:(CanvasView *)view didTrackObjectView:(CanvasObjectView *)objectView
{
    if ([objectView isKindOfClass:[RectangleObjectView class]] ||
        [objectView isKindOfClass:[GrappleObjectView   class]])
    {
        [self _selectObject:[objectView canvasObject]];
    }
}


- (NSCursor *) cursorForCanvasView:(CanvasView *)view
{
    return [[_toolbox selectedTool] cursor];
}


- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event
{
    if ([_toolbox selectedToolType] == ToolTypeGrapple) {
        _lastPreviewGrapplePoint = [_canvasView canvasPointForEvent:event];
        [self _updatePreviewGrapple];
    }
}


- (void) canvasView:(CanvasView *)view mouseExitedWithEvent:(NSEvent *)event
{
    if ([_toolbox selectedToolType] == ToolTypeGrapple) {
        _lastPreviewGrapplePoint = NSMakePoint(NAN, NAN);
        [self _updatePreviewGrapple];
    }
}


- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:(NSEvent *)event
{
    ToolType toolType = [_toolbox selectedToolType];

    if (toolType == ToolTypeHand) {
        [[_toolbox handTool] setActive:YES];
        _handEventStartPoint  = [event locationInWindow];
        _handCanvasStartPoint = [[_canvasScrollView documentView] visibleRect].origin;

        [_canvasView invalidateCursors];

    } else if (toolType == ToolTypeRectangle) {
        Rectangle *rectangle = [_canvas makeRectangle];

        CanvasObjectView *view = [self _viewForCanvasObject:rectangle];
       
        [view trackWithEvent:event newborn:YES];
        
        return NO;

    } else if (toolType == ToolTypeGrapple) {
        [self _removePreviewGrapple];
        
        Grapple *grapple = [_canvas makeGrappleVertical:[[_toolbox grappleTool] calculatedIsVertical]];

        CanvasObjectView *view = [self _viewForCanvasObject:grapple];

        UInt8 threshold = [[_toolbox grappleTool] calculatedThreshold];
        BOOL stopsOnGuides = YES;

        if ([view isKindOfClass:[GrappleObjectView class]]) {
            GrappleObjectView *grappleView = (GrappleObjectView *)view;
            [grappleView setOriginalThreshold:threshold];
            [grappleView setOriginalStopsOnGuides:stopsOnGuides];
        }
        
        [view trackWithEvent:event newborn:YES];
        
        return NO;
    
    } else if (toolType == ToolTypeMarquee) {
        Marquee *marquee = [_canvas makeMarquee];

        CanvasObjectView *view = [self _viewForCanvasObject:marquee];
        [view trackWithEvent:event newborn:YES];

        return NO;
    

    } else if (toolType == ToolTypeMove) {
        [self _unselectAllObjects];
        return NO;
    }

    return YES;
}

- (void) canvasView:(CanvasView *)view mouseDraggedWithEvent:(NSEvent *)event
{
    ToolType toolType = [_toolbox selectedToolType];

    if (toolType == ToolTypeHand) {
        NSPoint eventCurrentPoint = [event locationInWindow];

        NSPoint movedPoint = NSMakePoint(
            _handCanvasStartPoint.x - (eventCurrentPoint.x - _handEventStartPoint.x),
            _handCanvasStartPoint.y + (eventCurrentPoint.y - _handEventStartPoint.y)
        );
        
        NSRect rect = NSZeroRect;
        rect.origin = movedPoint;
        rect = [[_canvasScrollView contentView] constrainBoundsRect:rect];
        movedPoint = rect.origin;
        
        [[_canvasScrollView contentView] scrollToPoint:movedPoint];
        [_canvasScrollView reflectScrolledClipView:[_canvasScrollView contentView]];
    }
}


- (void) canvasView:(CanvasView *)view mouseUpWithEvent:(NSEvent *)event
{
    ToolType toolType = [_toolbox selectedToolType];

    if (toolType == ToolTypeHand) {
        [[_toolbox handTool] setActive:NO];
        [_canvasView invalidateCursors];

    } else  if (toolType == ToolTypeZoom) {
        _zoomEvent = event;
        [[_toolbox zoomTool] zoom];
    }
}


#pragma mark - Other Delegates

- (BOOL) rulerView:(RulerView *)rulerView mouseDownWithEvent:(NSEvent *)event
{
    Guide *guide = [_canvas makeGuideVertical:(rulerView == _verticalRuler)];
    
    CanvasObjectView *view = [self _viewForCanvasObject:guide];
    [view trackWithEvent:event newborn:YES];

    if ([guide isValid]) {
        [_toolbox setSelectedToolType:ToolTypeMove];
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

    if ([selfWindow firstResponder] != selfWindow) {
        [selfWindow makeFirstResponder:selfWindow];

    } else if (_selectedObject) {
        [self _unselectAllObjects];
    } else if (1 /* should close on escape */) {
        [self hide];
    }

    return YES;
}


- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *)window
{
    return [_canvas undoManager];
}

#pragma mark - Public Methods / IBActions

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromRect:(CGRect)fromRect
{
    [self window];  // Force nib to load

    CGImageRef image = [[libraryItem screenshot] CGImage];

    CGImageRelease(_transitionImage);
    _transitionImage = CGImageRetain(image);

    _transitionImageView = [[NSView alloc] initWithFrame:fromRect];
    [_transitionImageView setWantsLayer:YES];
    [[_transitionImageView layer] setContents:(__bridge id)_transitionImage];
    
    _transitionImageRect = fromRect;

    [self _updateWindowForScreen:[NSScreen mainScreen]];
    [self _updateCanvasWithLibraryItem:libraryItem];
    [self _doOrderInAnimation];

    [NSApp activateIgnoringOtherApps:YES];
    [[CursorInfo sharedInstance] setEnabled:YES];
    [[self window] makeKeyAndOrderFront:self];
}


- (void) toggleVisibility
{
    NSWindow *window = [self window];
    
    if ([window isVisible]) {
        [self hide];

    } else {
        [self _updateWindowForScreen:[NSScreen mainScreen]];

        [self _removeTransitionImage];

        if (!_selectedItem) {
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
    }
}


- (void) saveCurrentLibraryItem
{
    if (_selectedItem && _canvas) {
        [_selectedItem setCanvasDictionary:[_canvas dictionaryRepresentation]];
    }
}


- (void) hide
{
    [self saveCurrentLibraryItem];

    [[CursorInfo sharedInstance] setEnabled:NO];

    [self _doOrderOutAnimation];
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

        // Delete and remove
        [self hide];
    }
}


#pragma mark - Accessors

- (void) setSelectedObject:(CanvasObject *)selectedObject
{
    if (_selectedObject != selectedObject) {
        _selectedObject = selectedObject;
        [self _updateInspector];
    }
}

@end
