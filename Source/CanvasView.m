//
//  Canvas.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "CanvasView.h"

#import "Guide.h"
#import "CanvasLayer.h"
#import "Canvas.h"


@implementation CanvasView {
    CALayer        *_container;
    CALayer        *_imageLayer;
    NSMutableArray *_canvasLayers;
}

- (id) initWithFrame:(NSRect)frameRect canvas:(Canvas *)canvas
{
    if ((self = [super initWithFrame:frameRect])) {
        _imageLayer = [CALayer layer];
        _canvas = canvas;
        
        [self setWantsLayer:YES];
        [self setLayer:[CALayer layer]];

        [[self layer] addSublayer:_imageLayer];
        [[self layer] setMasksToBounds:YES];
        
        _container = [CALayer layer];
        [_container setDelegate:self];
        [_container setFrame:[self bounds]];
        [[self layer] addSublayer:_container];
        
        [_imageLayer setAnchorPoint:CGPointMake(0, 0)];
        [_imageLayer setMagnificationFilter:kCAFilterNearest];
        [_imageLayer setContentsGravity:kCAGravityBottomLeft];
        [_imageLayer setFrame:[self bounds]];
        [_imageLayer setDelegate:self];
        
        [_imageLayer setContents:(id)[canvas image]];

        [_container addSublayer:_imageLayer];
        
        _magnification = 1;
    }

    return self;
}


- (id) initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect canvas:nil];
}


- (BOOL) isFlipped
{
    return YES;
}


- (CGPoint) pointForMouseEvent:(NSEvent *)event
{
    return [self pointForMouseEvent:event layer:nil];
}


- (CGPoint) pointForMouseEvent:(NSEvent *)event layer:(CanvasLayer *)layer
{
    CGPoint location = [event locationInWindow];
    NSView *contentView = [[self window] contentView];
    
    CGFloat scale = [[self window] backingScaleFactor];
    
    location = [self convertPoint:location fromView:contentView];
    
    location.x = round((location.x / _magnification) * scale) / scale;
    location.y = round((location.y / _magnification) * scale) / scale;
    
    return location;
}



- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        return;
    }

    CGPoint point = [self pointForMouseEvent:event];
    
    if ([_delegate canvasView:self mouseDownWithEvent:event point:point]) {
        while (1) {
            event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            
            NSEventType type = [event type];
            if (type == NSLeftMouseUp) {
                point = [self pointForMouseEvent:event];
                [_delegate canvasView:self mouseUpWithEvent:event point:point];
                break;

            } else if (type == NSLeftMouseDragged) {
                point = [self pointForMouseEvent:event];
                [_delegate canvasView:self mouseDragWithEvent:event point:point];
            }
        }
    }
}


- (void) resetCursorRects
{
    NSCursor *mainCursor = [_delegate cursorForCanvasView:self];
    
    if (mainCursor) {
        [self addCursorRect:[self bounds] cursor:mainCursor];
    
    } else {
        for (CanvasLayer *layer in _canvasLayers) {
            NSCursor *cursor = [layer cursor];
            if (cursor) {
                [self addCursorRect:[layer frame] cursor:cursor];
            }
        }
    }
}


#pragma mark - Private Methods


#pragma mark -
#pragma mark CALayer Delegate

- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id)[NSNull null];
}



- (BOOL) layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window
{
    for (CALayer *layer in _canvasLayers) {
        [layer setContentsScale:newScale];
    }
    
    [[self layer] setContentsScale:newScale];
    [_container setContentsScale:newScale];
    [_imageLayer setContentsScale:newScale];

    return YES;
}


- (void) layoutSublayersOfLayer:(CALayer *)layer
{
    if (layer == _container) {
        CGSize canvasSize = [_canvas size];
        CGRect frame = { CGPointZero, canvasSize };
        frame.size.height *= 2;
        frame.size.width  *= 2;
        [_container setFrame:frame];

        CGAffineTransform transform = CGAffineTransformMakeScale(_magnification, _magnification);
        [_imageLayer setTransform:CATransform3DMakeAffineTransform(transform)];
        
        for (CanvasLayer *layer in _canvasLayers) {
            CGRect rect = [layer rectForCanvasLayout];
            
            if (rect.size.width  > frame.size.width)  rect.size.width  = frame.size.width;
            if (rect.size.height > frame.size.height) rect.size.height = frame.size.height;
            
            CGRect frame = CGRectApplyAffineTransform(rect, transform);
            
            NSEdgeInsets padding = [layer paddingForCanvasLayout];
            
            frame.origin.x    -= padding.left;
            frame.size.width  += (padding.left + padding.right);
            
            frame.origin.y    -= padding.top;
            frame.size.height += (padding.top + padding.bottom);
            
            NSLog(@"%@", NSStringFromRect(frame));
            [layer setFrame:frame];
        }
    }
}


#pragma mark - Public Methods

- (void) invalidateCursorRects
{
    [[self window] invalidateCursorRectsForView:self];
}


- (void) addCanvasLayer:(CanvasLayer *)layer
{
    if (!_canvasLayers) {
        _canvasLayers = [NSMutableArray array];
    }

    [layer setDelegate:self];
    [layer setContentsScale:[[self layer] contentsScale]];

    [_canvasLayers addObject:layer];
    [_container addSublayer:layer];
}


- (void) removeCanvasLayer:(CanvasLayer *)layer
{
    [layer setDelegate:nil];
    [layer removeFromSuperlayer];
    [_canvasLayers removeObject:layer];
}


- (void) updateCanvasLayer:(CanvasLayer *)layer
{
    [_container setNeedsLayout];
}


- (CanvasLayer *) canvasLayerWithPoint:(CGPoint)point
{
    point.x *= _magnification;
    point.y *= _magnification;

    CALayer *result = [_container hitTest:point];

    
    while (result && ![result isKindOfClass:[CanvasLayer class]]) {
        result = [result superlayer];
    }
    
    return (CanvasLayer *)result;
}


#pragma mark -
#pragma mark Accessors

- (void) setMagnification:(CGFloat)magnification
{
    if (_magnification != magnification) {
        _magnification = magnification;
        [_container setNeedsLayout];
    }
}



@end
