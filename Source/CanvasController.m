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

#import "CanvasView.h"
#import "RulerView.h"
#import "View.h"
#import "CenteringClipView.h"

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

#import "GuideLayer.h"
#import "GrappleLayer.h"
#import "RectangleLayer.h"
#import "MarqueeLayer.h"
#import "ResizeKnobLayer.h"
#import "ShroudView.h"
#import "CanvasWindow.h"


#import "GrappleCalculator.h"

#import "CursorAdditions.h"

@interface CanvasController () <CanvasWindowDelegate, ShroudViewDelegate, CanvasDelegate, CanvasViewDelegate, RulerViewDelegate>
@end


@implementation CanvasController {
    NSInteger _selectedToolIndex;

    ShroudView *_shroudView;
    NSView     *_transitionImageView;
    CGRect      _transitionImageRect;
    CGImageRef  _transitionImage;

    CanvasLayer *_draggedLayer;

    Grapple     *_previewGrapple;
    
    Tool *_selectedTool;
    NSEvent *_zoomEvent;

    CGPoint _lastGrapplePoint;

    Canvas  *_canvas;
    LibraryItem *_selectedItem;
    NSMutableDictionary *_GUIDToLayerMap;
    
    CanvasObject   *_selectedObject;
    NSMutableArray *_selectionLayers;
}



+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;

    if ([key isEqualToString:@"selectedTool"]) {
        affectingKeys = @[ @"selectedToolIndex" ];
    } else if ([key isEqualToString:@"selectedToolIndex"]) {
        affectingKeys = @[ @"selectedTool" ];
    }
    
    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    
    return keyPaths;
}


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        _GUIDToLayerMap = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];

        _moveTool      = [[MoveTool      alloc] init];
        _handTool      = [[HandTool      alloc] init];
        _marqueeTool   = [[MarqueeTool   alloc] init];
        _rectangleTool = [[RectangleTool alloc] init];
        _grappleTool   = [[GrappleTool   alloc] init];
        _zoomTool      = [[ZoomTool      alloc] init];

        [_zoomTool addObserver:self forKeyPath:@"magnificationLevel" options:0 context:NULL];

        _library = [Library sharedInstance];
    }
    
    return self;
}


- (void) dealloc
{
    [_zoomTool removeObserver:self forKeyPath:@"magnificationLevel" context:NULL];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) flagsChanged:(NSEvent *)theEvent
{
    [_canvasView invalidateCursorRects];
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
            [self setSelectedTool:_zoomTool];
            return;

        } else if (c == 'h') {
            [self setSelectedTool:_handTool];
            return;
        
        } else if (c == 'm') {
            [self setSelectedTool:_marqueeTool];
            return;
        
        } else if (c == 'v') {
            [self setSelectedTool:_moveTool];
            return;

        } else if (c == 'r') {
            [self setSelectedTool:_rectangleTool];
            return;

        } else if (c == 'g') {
            [self setSelectedTool:_grappleTool];
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

        } else  if (c == ';') {
            // Toggle guides
            return;

        } else if (c == '-') {
            [_zoomTool zoomOut];
            return;

        } else if (c == '+') {
            [_zoomTool zoomIn];
            return;

        } else if (c == '1') {
            [_zoomTool zoomToMagnificationLevel:1.0];
            return;

        } else if (c == '2') {
            [_zoomTool zoomToMagnificationLevel:2.0];
            return;

        } else if (c == '3') {
            [_zoomTool zoomToMagnificationLevel:3.0];
            return;

        } else if (c == '4') {
            [_zoomTool zoomToMagnificationLevel:4.0];
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

    CanvasWindow *window = [[CanvasWindow alloc] initWithContentRect:CGRectMake(0, 0, 640, 400) styleMask:0 backing:NSBackingStoreBuffered defer:NO];
    NSView *contentView = [window contentView];
    [contentView setWantsLayer:YES];

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

    [contentView addSubview:_contentTopLevelView];

    [window setHasShadow:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setOpaque:NO];

//    [window setLevel:NSScreenSaverWindowLevel];

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



- (void) _removeTransitionImage
{
    CGImageRelease(_transitionImage);
    _transitionImage = NULL;
    
    [_transitionImageView removeFromSuperview];
    _transitionImageView = nil;

    _transitionImageRect = CGRectZero;
}



- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _zoomTool) {
        if ([keyPath isEqualToString:@"magnificationLevel"]) {
            CGFloat magnification = [_zoomTool magnificationLevel];

            [_horizontalRuler setMagnification:magnification];
            [_verticalRuler   setMagnification:magnification];
            [_canvasView      setMagnification:magnification];

            if (_zoomEvent) {
                CGRect clipViewFrame = [[_canvasScrollView contentView] frame];
                CGPoint zoomPoint = [_canvasView pointForMouseEvent:_zoomEvent];

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
            [self _updateCanvasWithLibraryItem:item];
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

- (void) _doOrderInAnimation
{
    NSDisableScreenUpdates();

    if (_transitionImageView) {
        NSView *contentView = [[self window] contentView];

        [contentView addSubview:_transitionImageView];
        
        CGRect frame = [[self window] convertRectFromScreen:_transitionImageRect];
        frame = [contentView convertRect:frame fromView:nil];
        [_transitionImageView setFrame:frame];

        [_canvasScrollView setHidden:YES];
    }

    [_shroudView setAlphaValue:0];
    [_contentTopLevelView setAlphaValue:0];

    [[self window] display];
    NSEnableScreenUpdates();

    CGSize size = [_contentTopLevelView bounds].size;

    __weak id weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.25];
        [[_shroudView animator] setAlphaValue:1.0];
        [[_contentTopLevelView animator] setAlphaValue:1.0];

        if (_transitionImageView) {
            CGRect fromRect = [_transitionImageView frame];
            
            CGFloat magnificationLevel = [_zoomTool magnificationLevel];
            CGRect toRect = CGRectApplyAffineTransform(fromRect, CGAffineTransformMakeScale(magnificationLevel, magnificationLevel));
            
            CGRect scrollRectInWindow = [_canvasScrollView convertRect:[_canvasScrollView bounds] toView:nil];
            
            toRect.origin.x = scrollRectInWindow.origin.x + round((scrollRectInWindow.size.width  - toRect.size.width)  / 2);
            toRect.origin.y = scrollRectInWindow.origin.y + round((scrollRectInWindow.size.height - toRect.size.height) / 2);
            
            [[_transitionImageView animator] setFrame:toRect];
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
    }
}


- (void) _doOrderOutAnimation
{
    CGSize size = [_contentTopLevelView bounds].size;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:0.25];
        [[_shroudView animator] setAlphaValue:0.0];
        [[_contentTopLevelView animator] setAlphaValue:0.0];
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
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    for (CanvasLayer *layer in [_GUIDToLayerMap allValues]) {
        [layer preferencesDidChange:preferences];
    }
}


- (CanvasLayer *) _layerForCanvasObject:(CanvasObject *)object
{
    if (!object) return nil;
    return [_GUIDToLayerMap objectForKey:[object GUID]];
}


- (void) shroudView:(ShroudView *)shroudView clickedWithEvent:(NSEvent *)event
{
    if (shroudView == _shroudView) {
        [self hide];
    } else if (shroudView == _contentTopLevelView) {
        [[self window] makeFirstResponder:[self window]];
    }
}


#pragma mark - Selection

- (void) _selectObject:(CanvasObject *)object
{
    [self _unselectAllObjects];

    if (!_selectionLayers) {
        _selectionLayers = [NSMutableArray array];
    }

    if ([object isKindOfClass:[Rectangle class]]) {
        CanvasLayer *parentLayer = [self _layerForCanvasObject:object];
        
        for (ResizeKnobType type = 0; type <= ResizeKnobBottomRight; type++) {
            ResizeKnobLayer *layer = [ResizeKnobLayer layer];
            [layer setType:type];
            
            [layer setParentLayer:parentLayer];
            
            [_canvasView addCanvasLayer:layer];
            
            [_selectionLayers addObject:layer];
        }
    }
    
    [self setSelectedObject:object];
}


- (void) _unselectAllObjects
{
    for (ResizeKnobLayer *layer in _selectionLayers) {
        [_canvasView removeCanvasLayer:layer];
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


#pragma mark -

- (void) _updatePreviewGrapple
{
    if (![_selectedTool isKindOfClass:[GrappleTool class]]) {
        [[CursorInfo sharedInstance] setText:nil forKey:@"preview-grapple"];
        [_canvas removePreviewGrapple];
        return;
    }

    GrappleTool *grappleTool = (GrappleTool *)_selectedTool;
    
    BOOL isVertical = [grappleTool calculatedIsVertical];

    if ([[_canvas previewGrapple] isVertical] != isVertical) {
        [[CursorInfo sharedInstance] setText:nil forKey:@"preview-grapple"];
        [_canvas removePreviewGrapple];
    }

    if (![_canvas previewGrapple]) {
        [_canvas makePreviewGrappleVertical:isVertical];
    }
    
    Grapple *previewGrapple = [_canvas previewGrapple];
    
    CGPoint point = _lastGrapplePoint;
    [_canvas updateGrapple:previewGrapple point:point threshold:[grappleTool calculatedThreshold] stopsOnGuides:YES];

    NSString *previewText = GetStringForFloat([previewGrapple length]);
    NSLog(@"%@", previewText);
    [[CursorInfo sharedInstance] setText:previewText forKey:@"preview-grapple"];
}


#pragma mark - Canvas Delegate

- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object
{
    CanvasLayer *layer = nil;

    if ([object isKindOfClass:[Guide class]]) {
        GuideLayer *guideLayer = [GuideLayer layer];
        [guideLayer setGuide:(Guide *)object];
        layer = guideLayer;

    } else if ([object isKindOfClass:[Grapple class]]) {
        GrappleLayer *grappleLayer = [GrappleLayer layer];
        [grappleLayer setGrapple:(Grapple *)object];
        layer = grappleLayer;

    } else if ([object isKindOfClass:[Rectangle class]]) {
        RectangleLayer *rectangleLayer = [RectangleLayer layer];
        [rectangleLayer setRectangle:(Rectangle *)object];
        layer = rectangleLayer;

    } else if ([object isKindOfClass:[Marquee class]]) {
        MarqueeLayer *marqueeLayer = [MarqueeLayer layer];
        [marqueeLayer setMarquee:(Marquee *)object];
        layer = marqueeLayer;
    }
    
    if (layer) {
        [_GUIDToLayerMap setObject:layer forKey:[object GUID]];
        [_canvasView addCanvasLayer:layer];
    }
}


- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object
{
    CanvasLayer *layer = [self _layerForCanvasObject:object];

    if (layer) {
        [_canvasView updateCanvasLayer:layer];
    }
}


- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object
{
    CanvasLayer *layer = [self _layerForCanvasObject:object];

    if (object == _selectedObject) {
        [self _unselectAllObjects];
    }
    
    if (layer) {
        [_canvasView removeCanvasLayer:layer];
    }
}


#pragma mark - RulerView Delegate

- (BOOL) rulerView:(RulerView *)view mouseDownWithEvent:(NSEvent *)event
{
    Guide *guide = [_canvas makeGuideVertical:(view == _verticalRuler)];
    _draggedLayer = [self _layerForCanvasObject:guide];
    return YES;
}


- (void) rulerView:(RulerView *)view mouseDragWithEvent:(NSEvent *)event
{
    if (_draggedLayer) {
        CGPoint point = [_canvasView pointForMouseEvent:event layer:_draggedLayer];
        [_draggedLayer mouseDragWithEvent:event point:point];
    }
}


- (void) rulerView:(RulerView *)view mouseUpWithEvent:(NSEvent *)event
{
    if (_draggedLayer) {
        CGPoint point = [_canvasView pointForMouseEvent:event layer:_draggedLayer];
        [_draggedLayer mouseUpWithEvent:event point:point];
    }
    
    [_canvasView invalidateCursorRects];
    
    _draggedLayer = nil;
}


#pragma mark - CanvasView Delegate

- (NSCursor *) cursorForCanvasView:(CanvasView *)view
{
    return [_selectedTool cursor];
}

- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event
{
    if ([_selectedTool isKindOfClass:[GrappleTool class]]) {
        _lastGrapplePoint = [_canvasView pointForMouseEvent:event];
        [self _updatePreviewGrapple];
    }
}


- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point
{
    ToolType toolType = [_selectedTool type];

    if (toolType == ToolTypeMove || toolType == ToolTypeRectangle || toolType == ToolTypeMarquee || toolType == ToolTypeGrapple) {
        CanvasLayer *layer = [view canvasLayerForMouseEvent:event];
        
        Grapple *previewGrapple = [_canvas previewGrapple];
        if (previewGrapple && ([layer canvasObject] == previewGrapple)) {
            layer = nil;
        }
        
        if ([layer isKindOfClass:[RectangleLayer class]]  ||
            [layer isKindOfClass:[MarqueeLayer   class]]  ||
            [layer isKindOfClass:[GrappleLayer   class]])
        {
            [self _selectObject:[layer canvasObject]];
        }

        if (!layer) {
            if (toolType == ToolTypeRectangle) {
                Rectangle *rectangle = [_canvas makeRectangle];

                layer = [self _layerForCanvasObject:rectangle];
                [layer setNewborn:YES];

                [self _selectObject:rectangle];

                
            } else if (toolType == ToolTypeMarquee) {
                [_canvas clearMarquee];

                Marquee *marquee = [_canvas makeMarquee];

                layer = [self _layerForCanvasObject:marquee];
                [layer setNewborn:YES];
                
            } else if (toolType == ToolTypeGrapple) {
                [[CursorInfo sharedInstance] setText:nil forKey:@"preview-grapple"];
                [_canvas removePreviewGrapple];
                
                Grapple *grapple = [_canvas makeGrappleVertical:[_grappleTool calculatedIsVertical]];

                layer = [self _layerForCanvasObject:grapple];
                [layer setNewborn:YES];

                point = [_canvasView pointForMouseEvent:event layer:layer];

                UInt8 threshold = [_grappleTool calculatedThreshold];
                BOOL stopsOnGuides = YES;

                if ([layer isKindOfClass:[GrappleLayer class]]) {
                    GrappleLayer *grappleLayer = (GrappleLayer *)layer;

                    [grappleLayer setOriginalPoint:point];
                    [grappleLayer setOriginalThreshold:threshold];
                    [grappleLayer setOriginalStopsOnGuides:stopsOnGuides];
                }
                
                [_canvas updateGrapple:grapple point:point threshold:threshold stopsOnGuides:stopsOnGuides];
                
                _draggedLayer = layer;
                return [layer mouseDownWithEvent:event point:point];
            }
        }

        _draggedLayer = layer;
        point = [_canvasView pointForMouseEvent:event layer:layer];
        return [layer mouseDownWithEvent:event point:point];
    }
    
    return YES;
}


- (void) canvasView:(CanvasView *)view mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if (_draggedLayer) {
        point = [_canvasView pointForMouseEvent:event layer:_draggedLayer];
        [_draggedLayer mouseDragWithEvent:event point:point];
    }
}


- (void) canvasView:(CanvasView *)view mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if (_draggedLayer) {
        point = [_canvasView pointForMouseEvent:event layer:_draggedLayer];
        [_draggedLayer mouseUpWithEvent:event point:point];
        
        CanvasObject *canvasObject = [_draggedLayer canvasObject];
        if (![canvasObject isValid]) {
            [_canvas removeObject:canvasObject];
        }

    } else if ([_selectedTool isKindOfClass:[ZoomTool class]]) {
        _zoomEvent = event;
        [(ZoomTool *)_selectedTool zoom];
    }

    [_canvasView resetCursorRects];

    [_draggedLayer setNewborn:NO];

    _draggedLayer = nil;
}


#pragma mark - Window Delegate

- (BOOL) window:(CanvasWindow *)window cancelOperation:(id)sender
{
    [self hide];
    return YES;
}


#pragma mark - Collection View Delegate



#pragma mark - Public Methods / IBActions

- (void) _updateCanvasWithLibraryItem:(LibraryItem *)item
{
    Screenshot *screenshot = [item screenshot];

    // Step two, update canvas if needed
    if ([_canvas screenshot] != screenshot) {
        [self _unselectAllObjects];
        _lastGrapplePoint = CGPointZero;
        
        _GUIDToLayerMap = [NSMutableDictionary dictionary];

        // Write out current canvas to disk
        if (_selectedItem && _canvas) {
            [_selectedItem setCanvasDictionary:[_canvas dictionaryRepresentation]];
        }
        
        Canvas *canvas = [[Canvas alloc] initWithDelegate:self];
        _canvas = canvas;
        _selectedItem = item;

        CanvasView *canvasView = [[CanvasView alloc] initWithFrame:CGRectZero canvas:canvas];
        [canvasView setDelegate:self];
        _canvasView = canvasView;

        [_canvasScrollView setDocumentView:canvasView];
        
        [_canvasView sizeToFit];

        [canvas setupWithScreenshot:screenshot dictionary:[item canvasDictionary]];
    }

    // Step three, figure out magnification level
    {
        NSSize  availableSize = [_canvasScrollView bounds].size;
        CGFloat backingScale  = [[_canvasScrollView window] backingScaleFactor];
        
        availableSize.width  *= backingScale;
        availableSize.height *= backingScale;
        
        NSSize canvasSize    = [_canvas size];

        CGFloat xScale = availableSize.width / canvasSize.width;
        CGFloat yScale = availableSize.height / canvasSize.height;
        
        NSInteger index = [_zoomTool magnificationIndexForLevel:(xScale < yScale ? xScale : yScale)];
        
        [_zoomTool setMagnificationIndex:index];
    }
}

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromRect:(CGRect)fromRect
{
    Screenshot *screenshot = [Screenshot screenshotWithContentsOfFile:[libraryItem screenshotPath]];

    CGImageRef image = [screenshot CGImage];

    CGImageRelease(_transitionImage);
    _transitionImage = CGImageRetain(image);

    _transitionImageView = [[NSView alloc] initWithFrame:fromRect];
    [_transitionImageView setWantsLayer:YES];
    [[_transitionImageView layer] setContents:(__bridge id)_transitionImage];
    
    _transitionImageRect = fromRect;

    NSScreen *screen = [NSScreen mainScreen];

    // Step one, update window and main view
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
    }

    [self _updateCanvasWithLibraryItem:libraryItem];

    [self _doOrderInAnimation];

    [NSApp activateIgnoringOtherApps:YES];
    [[CursorInfo sharedInstance] setEnabled:YES];
    [[self window] makeKeyAndOrderFront:self];
}


- (void) presentWithLastImage
{
    [self _removeTransitionImage];

    [self _doOrderInAnimation];

    [NSApp activateIgnoringOtherApps:YES];
    [[CursorInfo sharedInstance] setEnabled:YES];
    [[self window] makeKeyAndOrderFront:self];
}


- (void) hide
{
    // Write out current canvas to disk
    if (_selectedItem && _canvas) {
        [_selectedItem setCanvasDictionary:[_canvas dictionaryRepresentation]];
    }

    [[CursorInfo sharedInstance] setEnabled:NO];

    [self _doOrderOutAnimation];
}


#pragma mark - Accessors

- (void) setSelectedTool:(Tool *)selectedTool
{
    @synchronized(self) {
        if (_selectedTool != selectedTool) {
            _selectedTool = selectedTool;
            [self _updatePreviewGrapple];
            [_canvasView invalidateCursorRects];

            _selectedToolIndex = [[self allTools] indexOfObject:selectedTool];
            [self _updateInspector];
        }
    }
}


- (NSArray *) allTools
{
    return @[ _moveTool, _handTool, _marqueeTool, _rectangleTool, _grappleTool, _zoomTool ];
}


- (void) _updateInspector
{
    ToolType type = [[self selectedTool] type];
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



#pragma mark - Accessors

- (void) setSelectedToolIndex:(NSInteger)selectedToolIndex
{
    @synchronized(self) {
        if (_selectedToolIndex != selectedToolIndex) {
            _selectedToolIndex = selectedToolIndex;
            _selectedTool = [[self allTools] objectAtIndex:selectedToolIndex];
            [self _updateInspector];
        }

    }
}


- (NSInteger) selectedToolIndex
{
    @synchronized(self) {
        return _selectedToolIndex;
    }
}


- (Tool *) selectedTool
{
    @synchronized(self) {
        return _selectedTool;
    }
}


- (void) setSelectedObject:(CanvasObject *)selectedObject
{
    @synchronized(self) {
        if (_selectedObject != selectedObject) {
            _selectedObject = selectedObject;
            [self _updateInspector];
        }
    }
}


- (CanvasObject *) selectedObject
{
    @synchronized(self) {
        return _selectedObject;
    }
}


@end
