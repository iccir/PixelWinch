//
//  DocumentController.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "CanvasController.h"



#import "CanvasView.h"
#import "RulerView.h"
#import "View.h"
#import "CenteringClipView.h"

#import "Tool.h"
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

#import "GrappleCalculator.h"

#import "CursorAdditions.h"

@interface CanvasController () <CanvasDelegate, CanvasViewDelegate, RulerViewDelegate>
@end


@implementation CanvasController {
    NSView       *_containerView;

    NSScrollView *_scrollView;
    CanvasView   *_canvasView;

    RulerView *_horizontalRuler;
    RulerView *_verticalRuler;

    CanvasLayer *_draggedLayer;

    GrappleCalculator *_grappleCalculator;
    Grapple           *_hoverGrapple;
    
    Tool *_selectedTool;
    ZoomTool *_zoomTool;
    NSEvent *_zoomEvent;

    CGPoint _lastGrapplePoint;

    Canvas  *_canvas;
    NSMutableDictionary *_GUIDToLayerMap;
    
    NSMutableArray *_selectedObjects;
    NSMutableArray *_selectionLayers;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _GUIDToLayerMap = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
    }
    
    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) flagsChanged:(NSEvent *)theEvent
{
    [_canvasView invalidateCursorRects];
    [self _updateHoverGrapple];
    [super flagsChanged:theEvent];
}


- (void) loadView
{
    CGSize size = CGSizeMake(480, 320);
    CGRect rect = { CGPointZero, size };

    _containerView = [[View alloc] initWithFrame:rect];

    _horizontalRuler = [[RulerView alloc] initWithFrame:CGRectMake(16, 0, 480 - 16, 16)];
    [_horizontalRuler setAutoresizingMask:NSViewMaxYMargin|NSViewWidthSizable];
    [_horizontalRuler setDelegate:self];

    _verticalRuler = [[RulerView alloc] initWithFrame:CGRectMake(0, 16, 16, 320 - 16)];
    [_verticalRuler setAutoresizingMask:NSViewMaxXMargin|NSViewHeightSizable];
    [_verticalRuler setDelegate:self];

    NSImage *testImage = [NSImage imageNamed:@"TestImage"];
    CGImageRef image = [[[testImage representations] lastObject] CGImage];
    
    _canvas = [[Canvas alloc] initWithDelegate:self];
    [_canvas setupWithImage:image];

    _canvasView = [[CanvasView alloc] initWithFrame:rect canvas:_canvas];
    [_canvasView setDelegate:self];

    _scrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(16, 16, 480 - 16, 320 - 16)];

    CenteringClipView *clipView = [[CenteringClipView alloc] initWithFrame:[[_scrollView contentView] frame]];
    [_scrollView setContentView:clipView];
    
    [_scrollView setDocumentView:_canvasView];
    [_scrollView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:YES];

    [_containerView addSubview:_scrollView];
    [_containerView addSubview:_horizontalRuler];
    [_containerView addSubview:_verticalRuler];

    [self setView:_containerView];
}


#pragma mark - Private Methods

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


#pragma mark - Selection

- (void) _selectObject:(CanvasObject *)object
{
    if (!_selectionLayers) {
        _selectionLayers = [NSMutableArray array];
    }

    if (!_selectedObjects) {
        _selectedObjects = [NSMutableArray array];
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
        
        [_selectedObjects addObject:[parentLayer canvasObject]];
    }
    
    [self setSelectedObject:object];
}

- (void) _unselectAllObjects
{
    for (ResizeKnobLayer *layer in _selectionLayers) {
        [_canvasView removeCanvasLayer:layer];
    }
    
    _selectedObjects = nil;
    _selectionLayers = nil;
}


- (BOOL) deleteSelectedObjects
{
    NSArray *selectedObjects = _selectedObjects;
    
    if ([selectedObjects count]) {
        [self _unselectAllObjects];

        for (CanvasObject *object in selectedObjects) {
            [_canvas removeObject:object];
        }

        return YES;
    }
    
    return NO;
}



#pragma mark -

- (void) _updateHoverGrapple
{
    if (![_selectedTool isKindOfClass:[GrappleTool class]]) {
        if (_hoverGrapple) [_canvas removeGrapple:_hoverGrapple];
        _hoverGrapple = nil;
        return;
    }

    GrappleTool *grappleTool = (GrappleTool *)_selectedTool;
    
    BOOL isVertical = [grappleTool calculatedIsVertical];

    if ([_hoverGrapple isVertical] != isVertical) {
        [_canvas removeGrapple:_hoverGrapple];
        _hoverGrapple = nil;
    }

    if (!_hoverGrapple) {
        _hoverGrapple = [_canvas makeGrappleVertical:isVertical];
    }
    
    if (!_grappleCalculator) {
        _grappleCalculator = [[GrappleCalculator alloc] initWithImage:[_canvas image]];
    }

    CGPoint point = _lastGrapplePoint;
    UInt8 threshold = ([grappleTool tolerance] / 100.0) * 255.0;

    if (isVertical) {
        point.x = floor(point.x) + 0.5;
        point.y = floor(point.y);
    
        size_t y1, y2;
        [_grappleCalculator calculateVerticalGrappleWithStartX: point.x
                                                        startY: point.y
                                                     threshold: threshold
                                                         outY1: &y1
                                                         outY2: &y2];

        [_hoverGrapple setRect:CGRectMake(point.x, y1, 0, y2 - y1)];

    } else {
        point.x = floor(point.x);
        point.y = floor(point.y) + 0.5;
    
        size_t x1, x2;
        [_grappleCalculator calculateHorizontalGrappleWithStartX: point.x
                                                          startY: point.y
                                                       threshold: threshold
                                                           outX1: &x1
                                                           outX2: &x2];

        [_hoverGrapple setRect:CGRectMake(x1, point.y, x2 - x1, 0)];
    }
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
        [self _updateHoverGrapple];
    }
}


- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point
{
    ToolType toolType = [_selectedTool type];

    if (toolType == ToolTypeMove) {
        CanvasLayer *layer = [view canvasLayerForMouseEvent:event];
        
        if ([layer isKindOfClass:[ResizeKnobLayer class]] ||
            [layer isKindOfClass:[GuideLayer class]])
        {
            _draggedLayer = layer;
            return [_draggedLayer mouseDownWithEvent:event point:point];
        }
        
        [self _unselectAllObjects];
        [self _selectObject:[layer canvasObject]];
        
        
//        _selectedLayer = layer;
//
//        for (CanvasLayer *layer in _canvasLayers) {
//            CGRect cursorRect = [layer cursorRect];
//            cursorRect = CGRectInset(cursorRect, -0.25, -0.25);
//        
//            if (CGRectContainsPoint([layer cursorRect], location)) {
//                return [layer object];
//            }
//        }


        // No-op
        
    } else if (toolType == ToolTypeRectangle) {
        Rectangle *rectangle = [_canvas makeRectangle];
        _draggedLayer = [self _layerForCanvasObject:rectangle];
        
        CGRect rect = { point, CGSizeZero };
        [rectangle setRect:rect];
        
    } else if (toolType == ToolTypeMarquee) {
        [_canvas clearMarquee];
        
        CGRect rect = { point, CGSizeZero };
        Marquee *marquee = [_canvas makeMarquee];
        [marquee setRect:rect];
        
        _draggedLayer = [self _layerForCanvasObject:marquee];
    }
    
    return YES;
}


- (void) canvasView:(CanvasView *)view mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if (_draggedLayer) {
        [_draggedLayer mouseDragWithEvent:event point:point];
    }
}


- (void) canvasView:(CanvasView *)view mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if (_draggedLayer) {
        [_draggedLayer mouseUpWithEvent:event point:point];

    } else if ([_selectedTool isKindOfClass:[ZoomTool class]]) {
        _zoomEvent = event;
        [(ZoomTool *)_selectedTool zoom];
    }

    [_canvasView resetCursorRects];

    _draggedLayer = nil;
}


#pragma mark -
#pragma mark Zooming

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _zoomTool) {
        if ([keyPath isEqualToString:@"magnificationLevel"]) {
            CGFloat magnification = [_zoomTool magnificationLevel];

            [_canvasView setMagnification:magnification];

            if (_zoomEvent) {
                CGRect clipViewFrame = [[_scrollView contentView] frame];
                CGPoint zoomPoint = [_canvasView pointForMouseEvent:_zoomEvent];

                zoomPoint.x *= magnification;
                zoomPoint.y *= magnification;

                zoomPoint.x -= NSWidth( clipViewFrame) / 2.0;
                zoomPoint.y -= NSHeight(clipViewFrame) / 2.0;
                
                [[_scrollView documentView] scrollPoint:zoomPoint];

                _zoomEvent = nil;
            }
        }
    }
}


#pragma mark -
#pragma mark Actions

- (IBAction) addHorizontalGuideAtCursor:(id)sender
{

}


- (IBAction) addVerticalGuideAtCursor:(id)sender
{

}


#pragma mark - Accessors

- (void) setSelectedTool:(Tool *)selectedTool
{
    @synchronized(self) {
        if (_selectedTool != selectedTool) {
            _selectedTool = selectedTool;
            [self _updateHoverGrapple];
            [_canvasView invalidateCursorRects];
        }
    }
}

- (Tool *) selectedTool
{
    @synchronized(self) {
        return _selectedTool;
    }
}


- (void) setZoomTool:(ZoomTool *)zoomTool
{
    @synchronized(self) {
        if (_zoomTool != zoomTool) {
            [_zoomTool removeObserver:self forKeyPath:@"magnificationLevel"];
            _zoomTool = zoomTool;
            [_zoomTool addObserver:self forKeyPath:@"magnificationLevel" options:0 context:0];
        }
    }
}


- (ZoomTool *) zoomTool
{
    @synchronized(self) {
        return _zoomTool;
    }
}


@end
