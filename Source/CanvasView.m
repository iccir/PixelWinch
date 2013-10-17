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
#import "CanvasRootLayer.h"
#import "Screenshot.h"


@implementation CanvasView {
    CanvasRootLayer *_root;
    CALayer         *_imageLayer;
    NSMutableArray  *_canvasLayers;
    NSTrackingArea  *_trackingArea;
}


- (id) initWithFrame:(NSRect)frameRect canvas:(Canvas *)canvas
{
    if ((self = [super initWithFrame:frameRect])) {
        _canvas = canvas;
        
        CALayer *selfLayer = [CALayer layer];
        
        [self setWantsLayer:YES];
        [self setLayer:selfLayer];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];

        [selfLayer setBackgroundColor:[[NSColor colorWithRed:1 green:0 blue:0 alpha:0.25] CGColor]];
        [selfLayer setOpaque:YES];

        _root = [CanvasRootLayer layer];
        [_root setDelegate:self];
        [_root setFrame:[self bounds]];
        [selfLayer addSublayer:_root];

        _imageLayer = [CALayer layer];
        [_imageLayer setAnchorPoint:CGPointMake(0, 0)];
        [_imageLayer setMagnificationFilter:kCAFilterNearest];
        [_imageLayer setContentsGravity:kCAGravityBottomLeft];
        [_imageLayer setFrame:[self bounds]];
        [_imageLayer setDelegate:self];
        [_imageLayer setOpaque:YES];

        [_root addSublayer:_imageLayer];
        
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseMoved|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:_trackingArea];

        _magnification = 1;
    }

    return self;
}


- (id) initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect canvas:nil];
}


- (void) dealloc
{
    [self removeTrackingArea:_trackingArea];
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
    
    SnappingPolicy horizontalSnappingPolicy = [layer horizontalSnappingPolicy];
    SnappingPolicy verticalSnappingPolicy   = [layer verticalSnappingPolicy];
    
    location = [self convertPoint:location fromView:contentView];
    
    location.x = location.x / (_magnification / scale);
    location.y = location.y / (_magnification / scale);

    if (horizontalSnappingPolicy == SnappingPolicyToPixelEdge) {
        location.x = round(location.x);
    }
    
    if (verticalSnappingPolicy == SnappingPolicyToPixelEdge) {
        location.y = round(location.y);
    }

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

        [self invalidateCursorRects];
    }
}


- (void) mouseMoved:(NSEvent *)event
{
    return [_delegate canvasView:self mouseMovedWithEvent:event];
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


- (BOOL)wantsUpdateLayer {
   return YES;
}

- (void) updateLayer { }

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
    [_root setContentsScale:newScale];

    [_imageLayer setContentsScale:newScale];

    return YES;
}


- (void) layoutSublayersOfLayer:(CALayer *)layer
{
    if (layer == _root) {

        CGSize  size          = [_canvas size];

        CGFloat scale = [[self window] backingScaleFactor];
        if (!scale) scale = 1;

        size.width  *= (_magnification / scale);
        size.height *= (_magnification / scale);

        [self setFrame:CGRectMake(0, 0, size.width, size.height)];


        CGSize canvasSize = [_canvas size];
        CGRect frame = { CGPointZero, canvasSize };
        [_root setFrame:frame];

        [_imageLayer setTransform:CATransform3DIdentity];
        [_imageLayer setFrame:[_root bounds]];

        CGSize scrollViewSize = [[self enclosingScrollView] bounds].size;

        CGAffineTransform transform = CGAffineTransformMakeScale(_magnification, _magnification);
        [_imageLayer setTransform:CATransform3DMakeAffineTransform(transform)];
        [_imageLayer setContents:(id)[[_canvas screenshot] CGImage]];
        
        for (CanvasLayer *layer in _canvasLayers) {
            CGRect rect = [layer rectForCanvasLayout];

            if (rect.size.width == INFINITY) {
                rect.size.width = scrollViewSize.width;
            } else if (rect.size.width > frame.size.width) {
                rect.size.width = frame.size.width;
            }

            if (rect.size.height == INFINITY) {
                rect.size.height = scrollViewSize.height;
            
            } else if (rect.size.height > frame.size.height) {
                rect.size.height = frame.size.height;
            }


            if (rect.origin.x == -INFINITY) {
                rect.origin.x = -scrollViewSize.width;
                rect.size.width +=  scrollViewSize.width;
            }

            if (rect.origin.y == -INFINITY) {
                rect.origin.y = -scrollViewSize.height;
                rect.size.height += scrollViewSize.height;
            }
            
            CGAffineTransform scaledTransform = CGAffineTransformMakeScale(_magnification / scale, _magnification / scale);
            
            CGRect frame = CGRectApplyAffineTransform(rect, scaledTransform);
            
            NSEdgeInsets padding = [layer paddingForCanvasLayout];
            
            frame.origin.x    -= padding.left;
            frame.size.width  += (padding.left + padding.right);
            
            frame.origin.y    -= padding.top;
            frame.size.height += (padding.top + padding.bottom);
            
            [layer setFrame:frame];
        }
    }
}


#pragma mark - Public Methods

- (void) sizeToFit
{
    CGSize size = [_canvas size];

    CGFloat scale = [[self window] backingScaleFactor];
    if (!scale) scale = 1;

    size.width  *= (_magnification / scale);
    size.height *= (_magnification / scale);

    [self setFrame:CGRectMake(0, 0, size.width, size.height)];
}


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
    [_root addSublayer:layer];
}


- (void) removeCanvasLayer:(CanvasLayer *)layer
{
    [layer setDelegate:nil];
    [layer removeFromSuperlayer];
    [_canvasLayers removeObject:layer];
}


- (void) updateCanvasLayer:(CanvasLayer *)layer
{
    [_root setNeedsLayout];
}


- (CanvasLayer *) canvasLayerForMouseEvent:(NSEvent *)event
{
    CGPoint location = [event locationInWindow];
    NSView *contentView = [[self window] contentView];
    
    location = [self convertPoint:location fromView:contentView];

    CALayer *result = [_root hitTest:location];
    
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
        [self sizeToFit];
        [_root setNeedsLayout];
        [self invalidateCursorRects];
    }
}


- (BOOL) isOpaque
{
    return YES;
}


@end
