//
//  Canvas.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "CanvasView.h"

#import "Guide.h"
#import "CanvasObjectView.h"
#import "Canvas.h"
#import "Screenshot.h"

@implementation CanvasView {
    CALayer         *_imageLayer;
    XUIView         *_root;
    NSMutableArray  *_canvasObjectViews;
    NSTrackingArea  *_trackingArea;
    NSPoint          _cursorInvalidationMouseLocation;
}


- (id) initWithFrame:(CGRect)frameRect canvas:(Canvas *)canvas
{
    if ((self = [super initWithFrame:frameRect])) {
        _canvas = canvas;
        
        CALayer *selfLayer = [CALayer layer];
        
        [self setWantsLayer:YES];
        [self setLayer:selfLayer];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
        [selfLayer setDelegate:self];
        [selfLayer setOpaque:YES];

        _imageLayer = [CALayer layer];
        [_imageLayer setAnchorPoint:CGPointMake(0, 0)];
        [_imageLayer setMagnificationFilter:kCAFilterNearest];
        [_imageLayer setContentsGravity:kCAGravityBottomLeft];
        [_imageLayer setFrame:[self bounds]];
        [_imageLayer setDelegate:self];
        [_imageLayer setOpaque:YES];
        
        _root = [[XUIView alloc] initWithFrame:[self bounds]];
        [_root setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
        [self addSubview:_root];

        [[_root layer] addSublayer:_imageLayer];
        
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:_trackingArea];

        _magnification = 1;
    }

    return self;
}


- (id) initWithFrame:(CGRect)frameRect
{
    return [self initWithFrame:frameRect canvas:nil];
}


- (CanvasObjectView *) canvasObjectHitTest:(CGPoint)point
{
    for (CanvasObjectView *objectView in _canvasObjectViews) {
        CGPoint objectPoint = [objectView convertPoint:point fromView:self];
        BOOL    contains    = [[objectView layer] containsPoint:objectPoint];

        if (contains) {
            if ([_delegate canvasView:self shouldTrackObjectView:objectView]) {
                return objectView;
            }
        }
    }

    return nil;
}


- (void) _recomputeCursorRects
{
    NSPoint globalPoint = [NSEvent mouseLocation];
    NSRect  globalRect  = NSMakeRect(globalPoint.x, globalPoint.y, 0, 0);
    
    NSRect  windowRect = [[self window] convertRectFromScreen:globalRect];
    NSPoint windowPoint = windowRect.origin;

    NSPoint locationInSelf = [self convertPoint:windowPoint fromView:nil];
    
    if (![self hitTest:locationInSelf]) {
        return;
    }
    
    CanvasObjectView *view = [self canvasObjectHitTest:locationInSelf];
    NSCursor *cursor = [(id)view cursor];

    if (cursor) {
        [cursor set];
        return;
    }
    
    [[_delegate cursorForCanvasView:self] set];
}


- (void) dealloc
{
    [self removeTrackingArea:_trackingArea];
}


- (BOOL) isFlipped
{
    return YES;
}


- (void) cursorUpdate:(NSEvent *)event
{
    [self _recomputeCursorRects];
}


- (CGPoint) _canvasPointForPoint:(CGPoint)point round:(BOOL)shouldRound
{
    CGFloat scale = [[self window] backingScaleFactor];
    
    point.x = point.x / (_magnification / scale);
    point.y = point.y / (_magnification / scale);

    if (shouldRound) {
        point.x = round(point.x);
        point.y = round(point.y);
    }

    return point;
}


- (CGPoint) canvasPointForPoint:(CGPoint)point
{
    return [self _canvasPointForPoint:point round:NO];
}


- (CGPoint) canvasPointForEvent:(NSEvent *)event
{
    CGPoint location = [event locationInWindow];
    NSView *contentView = [[self window] contentView];
    
    location = [self convertPoint:location fromView:contentView];

    return [self _canvasPointForPoint:location round:NO];
}


- (CGPoint) roundedCanvasPointForPoint:(CGPoint)point
{
    return [self _canvasPointForPoint:point round:YES];
}


- (CGPoint) roundedCanvasPointForEvent:(NSEvent *)event
{
    CGPoint location = [event locationInWindow];
    NSView *contentView = [[self window] contentView];
    
    location = [self convertPoint:location fromView:contentView];

    return [self _canvasPointForPoint:location round:YES];
}


- (BOOL) convertMouseLocationToCanvasPoint:(CGPoint *)outPoint
{
    CGPoint globalMousePoint = [NSEvent mouseLocation];
    NSRect  globalMouseRect  = NSMakeRect(globalMousePoint.x, globalMousePoint.y, 0, 0);

    CGPoint location    = [[self window] convertRectFromScreen:globalMouseRect].origin;
    NSView *contentView = [[self window] contentView];

    location = [self convertPoint:location fromView:contentView];
    
    if ([self hitTest:location]) {
        *outPoint = [self _canvasPointForPoint:location round:NO];
        return YES;
    } else {
        return NO;
    }
}


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        return;
    }

    if ([_delegate canvasView:self mouseDownWithEvent:event]) {
        [self invalidateCursors];

        while (1) {
            event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];

            NSEventType type = [event type];
            if (type == NSLeftMouseUp) {
                [_delegate canvasView:self mouseUpWithEvent:event];
                break;

            } else if (type == NSLeftMouseDragged) {
                [_delegate canvasView:self mouseDraggedWithEvent:event];
            }
        }
    }

    [self invalidateCursors];
}


- (void) mouseMoved:(NSEvent *)event
{
    [self invalidateCursors];
    [_delegate canvasView:self mouseMovedWithEvent:event];
}


- (void) mouseEntered:(NSEvent *)theEvent
{
    [self invalidateCursors];
}


- (void) mouseExited:(NSEvent *)event
{
    [[NSCursor arrowCursor] set];
    [_delegate canvasView:self mouseExitedWithEvent:event];
    [self invalidateCursors];
}


- (BOOL) layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window
{
    [[self layer] setContentsScale:newScale];
    [_imageLayer setContentsScale:newScale];

    return YES;
}


- (void) layoutSubviews
{
    CGSize  size = [_canvas size];

    CGFloat scale = [[self window] backingScaleFactor];
    if (!scale) scale = 1;

    scale = (_magnification / scale);
    
    size.width  *= scale;
    size.height *= scale;

    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    [self setFrame:frame];

    [_root setFrame:[self bounds]];

    [_imageLayer setTransform:CATransform3DIdentity];
    [_imageLayer setFrame:[_root bounds]];

    CGAffineTransform transform = CGAffineTransformMakeScale(_magnification, _magnification);
    [_imageLayer setTransform:CATransform3DMakeAffineTransform(transform)];
    [_imageLayer setContents:(id)[[_canvas screenshot] CGImage]];
    
    for (CanvasObjectView *objectView in [_canvasObjectViews reverseObjectEnumerator]) {
        CGRect rect = [objectView rectForCanvasLayout];

//        if ((rect.size.width != INFINITY) && (rect.size.width > frame.size.width)) {
//            NSLog(@"clamping width: %g -> %g, %@ %g", rect.size.width, frame.size.width, NSStringFromSize([_canvas size]), scale);
//            rect.size.width = frame.size.width;
//        }
//
//        if ((rect.size.height != INFINITY) && (rect.size.height > frame.size.height)) {
//            rect.size.height = frame.size.height;
//        }

        const XUIEdgeInsets padding = [objectView paddingForCanvasLayout];

        rect.origin.x    *= scale;
        rect.origin.y    *= scale;
        rect.size.width  *= scale;
        rect.size.height *= scale;
        
        rect.origin.x    -= padding.left;
        rect.size.width  += (padding.left + padding.right);
        
        rect.origin.y    -= padding.top;
        rect.size.height += (padding.top + padding.bottom);
        
        
        CGSize sizeForInfinity = [[self enclosingScrollView] bounds].size;
        sizeForInfinity.width  += frame.size.width;
        sizeForInfinity.height += frame.size.height;

        if (rect.size.width == INFINITY) {
            rect.size.width = sizeForInfinity.width;
        }

        if (rect.size.height == INFINITY) {
            rect.size.height = sizeForInfinity.height;
        }

        if (rect.origin.x == -INFINITY) {
            rect.origin.x = -sizeForInfinity.width;
            rect.size.width +=  sizeForInfinity.width;
        }

        if (rect.origin.y == -INFINITY) {
            rect.origin.y = -sizeForInfinity.height;
            rect.size.height += sizeForInfinity.height;
        }
        
        [objectView setFrame:rect];
        
        [objectView removeFromSuperview];
        [_root addSubview:objectView];
    }
    
    [self _recomputeCursorRects];
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


- (void) invalidateCursors
{
    [self _recomputeCursorRects];
}


- (void) addCanvasObjectView:(CanvasObjectView *)view
{
    if (!_canvasObjectViews) {
        _canvasObjectViews = [NSMutableArray array];
    }

    [_canvasObjectViews addObject:view];
    [_canvasObjectViews sortUsingComparator:^(id a, id b) {
        return [b canvasOrder] - [a canvasOrder];
    }];
    
    [self addSubview:view];
}


- (void) removeCanvasObjectView:(CanvasObjectView *)view
{
    [view removeFromSuperview];
    [_canvasObjectViews removeObject:view];
}


- (void) updateCanvasObjectView:(CanvasObjectView *)layer
{
    [self setNeedsLayout];
}


- (BOOL) shouldTrackObjectView:(CanvasObjectView *)objectView
{
    return [_delegate canvasView:self shouldTrackObjectView:objectView];
}


- (void) willTrackObjectView:(CanvasObjectView *)objectView
{
    [_delegate canvasView:self willTrackObjectView:objectView];
}


- (void) didTrackObjectView:(CanvasObjectView *)objectView
{
    [_delegate canvasView:self didTrackObjectView:objectView];
}


#pragma mark -
#pragma mark Accessors

- (void) setMagnification:(CGFloat)magnification
{
    if (_magnification != magnification) {
        _magnification = magnification;
        [self sizeToFit];
        [self setNeedsLayout];
        [self invalidateCursors];
    }
}


- (BOOL) isOpaque
{
    return YES;
}


@end
