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

#import "Canvas.h"
#import "Guide.h"
#import "Grapple.h"
#import "Rectangle.h"
#import "Marquee.h"

#import "GuideLayer.h"
#import "RectangleLayer.h"
#import "MarqueeLayer.h"
#import "ResizeKnobLayer.h"

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

    Canvas *_canvas;

    NSMutableDictionary *_GUIDToLayerMap;
    
    NSMutableArray *_selectedObjects;
    NSMutableArray *_selectionLayers;

    ToolType _currentAction;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _GUIDToLayerMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (void) _layoutCanvas
{
    CGSize  size          = [_canvas size];
    CGFloat magnification = [_canvasView magnification];

    CGFloat scale = [[_canvasView window] backingScaleFactor];
    if (!scale) scale = 1;

    size.width  *= (magnification / scale);
    size.height *= (magnification / scale);

    [_canvasView setFrame:CGRectMake(0, 0, size.width, size.height)];
}



- (void) flagsChanged:(NSEvent *)theEvent
{
    [_canvasView invalidateCursorRects];
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

    NSImage *testImage = [NSImage imageNamed:@"test"];
    CGImageRef image = [[[testImage representations] lastObject] CGImage];
    
    _canvas = [[Canvas alloc] initWithDelegate:self];
    [_canvas setupWithImage:image];

    _canvasView = [[CanvasView alloc] initWithFrame:rect canvas:_canvas];
    [_canvasView setDelegate:self];
    [_canvasView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];

    _scrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(16, 16, 480 - 16, 320 - 16)];
    [_scrollView setDocumentView:_canvasView];
    [_scrollView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:YES];

    [_containerView addSubview:_scrollView];
    [_containerView addSubview:_horizontalRuler];
    [_containerView addSubview:_verticalRuler];

    [self setView:_containerView];

    [self _layoutCanvas];
}


#pragma mark - Private Methods

- (CGFloat) _magnificationForMagnification:(CGFloat)level direction:(NSInteger)direction
{
    static NSArray *sZoomLevels;
    if (!sZoomLevels) {
        sZoomLevels = @[
            @( 6    ),
            @( 12   ),
            @( 25   ),
            @( 50   ),
            @( 66   ),
            @( 100  ),
            @( 200  ),
            @( 300  ),
            @( 400  ),
            @( 800  ),
            @( 1600 ),
            @( 3200 ),
            @( 6400 )
        ];
    };
    
    NSUInteger iLevel = level * 100;

    if (direction > 0) {
        for (NSNumber *n in sZoomLevels) {
            if (iLevel < [n integerValue]) {
                iLevel = [n integerValue];
                break;
            }
        }
    
    } else if (direction < 0) {
        for (NSNumber *n in [sZoomLevels reverseObjectEnumerator]) {
            if (iLevel > [n integerValue]) {
                iLevel = [n integerValue];
                break;
            }
        }
    
    }
    
    return (CGFloat)iLevel / 100;
}


- (void) _updateMagnification:(CGFloat)magnification
{
    [_canvasView setMagnification:magnification];
    [self _layoutCanvas];
}


- (CanvasLayer *) _layerForCanvasObject:(CanvasObject *)object
{
    if (!object) return nil;
    return [_GUIDToLayerMap objectForKey:[object GUID]];
}


- (CanvasLayer *) _layerForCanvasPoint:(CGPoint)point
{
    return [_canvasView canvasLayerWithPoint:point];
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
}

- (void) _unselectAllObjects
{
    for (ResizeKnobLayer *layer in _selectionLayers) {
        [_canvasView removeCanvasLayer:layer];
    }
    
    _selectedObjects = nil;
    _selectionLayers = nil;
}


- (void) _deleteSelectedObjects
{
    NSArray *selectedObjects = _selectedObjects;
    
    [self _unselectAllObjects];
    for (CanvasObject *object in selectedObjects) {
        [_canvas removeObject:object];
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
    
    _draggedLayer = nil;
}


#pragma mark - CanvasView Delegate

- (NSCursor *) cursorForCanvasView:(CanvasView *)view
{
    if (_selectedTool == ToolTypeMarquee) {
        return [NSCursor crosshairCursor];
    } else if (_selectedTool == ToolTypeZoom) {
        return [NSCursor winch_zoomInCursor];
    }
    
    return nil;
    
}

- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if (_selectedTool == ToolTypeMove) {
        CanvasLayer *layer = [self _layerForCanvasPoint:point];

        if ([layer isKindOfClass:[ResizeKnobLayer class]] ||
            [layer isKindOfClass:[GuideLayer class]])
        {
            _draggedLayer = layer;
            return YES;
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
        
    } else if (_selectedTool == ToolTypeRectangle) {
        Rectangle *rectangle = [_canvas makeRectangle];
        _draggedLayer = [self _layerForCanvasObject:rectangle];
        
        CGRect rect = { point, CGSizeZero };
        [rectangle setRect:rect];
        
    } else if (_selectedTool == ToolTypeMarquee) {
        [_canvas clearMarquee];
        
        CGRect rect = { point, CGSizeZero };
        Marquee *marquee = [_canvas makeMarquee];
        [marquee setRect:rect];
        
        _draggedLayer = [self _layerForCanvasObject:marquee];
    }
    
    _currentAction = _selectedTool;

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

    } else if (_selectedTool == ToolTypeZoom) {
        NSInteger direction = ([event modifierFlags] & NSAlternateKeyMask) ? -1 : 1;
        [self zoomWithEvent:event direction:direction];
    }

    [_canvasView resetCursorRects];

    _draggedLayer = nil;
}


#pragma mark -
#pragma mark Zooming

- (void) zoomWithEvent:(NSEvent *)event direction:(NSInteger)direction
{
    CGFloat magnification = [_canvasView magnification];
    magnification = [self _magnificationForMagnification:magnification direction:direction];

    CGPoint zoomPoint;
    if (event) {
        zoomPoint = [_canvasView pointForMouseEvent:event];
    }

    [_canvasView setMagnification:magnification];
    [self _layoutCanvas];

    [_canvasView resetCursorRects];

    if (event) {
        CGRect clipViewFrame = [[_scrollView contentView] frame];
        
        zoomPoint.x *= magnification;
        zoomPoint.y *= magnification;

        zoomPoint.x -= NSWidth( clipViewFrame) / 2.0;
        zoomPoint.y -= NSHeight(clipViewFrame) / 2.0;
        
        [[_scrollView documentView] scrollPoint:zoomPoint];
    }
}


#pragma mark -
#pragma mark Actions

- (IBAction) zoomIn:(id)sender
{
    [self zoomWithEvent:nil direction:1];
}


- (IBAction) zoomOut:(id)sender
{
    [self zoomWithEvent:nil direction:-1];
}


- (IBAction) deleteSelectedObject:(id)sender
{
    [self _deleteSelectedObjects];
}


- (IBAction) addHorizontalGuideAtCursor:(id)sender
{

}


- (IBAction) addVerticalGuideAtCursor:(id)sender
{

}


#pragma mark - Accessors

- (void) setSelectedTool:(ToolType)selectedTool
{
    if (_selectedTool != selectedTool) {
        _selectedTool = selectedTool;
        [_canvasView invalidateCursorRects];
    }
}


@end
