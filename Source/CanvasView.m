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
#import "MeasurementLabel.h"

#import "LineObjectView.h"
#import "Line.h"


@implementation CanvasView {
    CALayer *_imageLayer;
    XUIView *_root;

    NSMutableArray      *_canvasObjectViews;
    NSMutableArray      *_measurementLabels;
    NSMutableDictionary *_GUIDToMeasurementLabelMap;

    NSMutableArray      *_labelConstraints;

    NSTrackingArea  *_trackingArea;
    BOOL             _needsObjectViewReorder;
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

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];

        _magnification = 1;
    }

    return self;
}


- (id) initWithFrame:(CGRect)frameRect
{
    return [self initWithFrame:frameRect canvas:nil];
}


- (void) dealloc
{
    [self removeTrackingArea:_trackingArea];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


- (CGRect) _labelFrameForLineObjectView: (LineObjectView *) lineObjectView
                           initialFrame: (CGRect) labelFrame
                   notIntersectingViews: (NSArray *) otherViews
{
    Line  *line     = [lineObjectView line];
    BOOL   vertical = [line isVertical];

    CGRect  myFrame = [lineObjectView frame];
    CGFloat weight  = 0;

    NSMutableArray *touchingLines = [NSMutableArray array];

    for (NSView *otherView in otherViews) {
        CGRect otherFrame   = [otherView frame];
        CGRect intersection = CGRectIntersection(otherFrame, myFrame);

        if (!CGRectIsEmpty(intersection)) {
            [touchingLines addObject:otherView];
            
            if (vertical) {
                weight += CGRectGetMidY(otherFrame) - CGRectGetMidY(myFrame);
            } else {
                weight += CGRectGetMidX(otherFrame) - CGRectGetMidX(myFrame);
            }
        }
    }

    NSInteger loopGuard = 1000;
    while (loopGuard-- > 0) {
        BOOL didCollide = NO;

        for (NSView *otherView in touchingLines) {
            CGRect otherFrame   = [otherView frame];
            CGRect intersection = CGRectIntersection(otherFrame, labelFrame);

            if (!CGRectIsEmpty(intersection)) {
                didCollide = YES;
                break;
            }
        }
            
        if (!didCollide) {
            break;
        }
        
        // Tweak the value of the label
        if (weight > 0) {
            if (vertical) {
                labelFrame.origin.y -= 1.0;

                if (labelFrame.origin.y < myFrame.origin.y) {
                    labelFrame.origin.y = myFrame.origin.y;
                    break;
                }

            } else {
                labelFrame.origin.x -= 1.0;

                if (labelFrame.origin.x < myFrame.origin.x) {
                    labelFrame.origin.x = myFrame.origin.x;
                    break;
                }
            }

        } else {
            if (vertical) {
                labelFrame.origin.y += 1.0;

                if ((labelFrame.origin.y + labelFrame.size.height) > CGRectGetMaxY(myFrame)) {
                    labelFrame.origin.y = CGRectGetMaxY(myFrame) - labelFrame.size.height;
                    break;
                }

            } else {
                labelFrame.origin.x += 1.0;

                if ((labelFrame.origin.x + labelFrame.size.width) > CGRectGetMaxX(myFrame)) {
                    labelFrame.origin.x = CGRectGetMaxX(myFrame) - labelFrame.size.width;
                    break;
                }
            }
        }
    }

    return labelFrame;
}


- (void) _layoutMeasurementLabels
{
    NSMutableArray *horizontalLineViews = [NSMutableArray array];
    NSMutableArray *verticalLineViews   = [NSMutableArray array];

    for (MeasurementLabel *canvasObjectView in _canvasObjectViews) {
        if ([canvasObjectView isKindOfClass:[LineObjectView class]]) {
            LineObjectView *lineObjectView = (LineObjectView *)canvasObjectView;
            Line *line = [lineObjectView line];

            if ([line isPreview]) continue;

            if ([[lineObjectView line] isVertical]) {
                [verticalLineViews addObject:lineObjectView];
            } else {
                [horizontalLineViews addObject:lineObjectView];
            }
        }
    }

    for (MeasurementLabel *label in _measurementLabels) {
        CanvasObjectView *objectView = [label owningObjectView];

        CGRect objectViewFrame = [objectView frame];

        CGSize contentSize = [label intrinsicContentSize];
       
        CGRect labelFrame = objectViewFrame;
        labelFrame.size = contentSize;
        labelFrame.origin.x += round((objectViewFrame.size.width  - contentSize.width)  / 2);
        labelFrame.origin.y += round((objectViewFrame.size.height - contentSize.height) / 2);
        
        [label setHidden:[objectView isMeasurementLabelHidden]];

        // Special case for lines - we don't want the text label for one line overlapping another line
        //
        if ([objectView isKindOfClass:[LineObjectView class]]) {
            LineObjectView *lineObjectView = (LineObjectView *)objectView;

            if ([[lineObjectView line] isVertical]) {
                labelFrame = [self _labelFrameForLineObjectView:lineObjectView initialFrame:labelFrame notIntersectingViews:horizontalLineViews];
            } else {
                labelFrame = [self _labelFrameForLineObjectView:lineObjectView initialFrame:labelFrame notIntersectingViews:verticalLineViews];
            }
        }

        [label setFrame:labelFrame];
    }
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
        
        if (_needsObjectViewReorder) {
            [objectView removeFromSuperview];
            [_root addSubview:objectView];
        }
    }
    
    [self _layoutMeasurementLabels];

    _needsObjectViewReorder = NO;

    [self _recomputeCursorRects];
}


- (CGPoint) canvasPointAtCenter
{
    NSRect visibleRect = [self visibleRect];
    
    CGPoint centerPoint = CGPointMake(
        NSMidX(visibleRect),
        NSMidY(visibleRect)
    );

    return [self canvasPointForPoint:centerPoint];
}


- (void) _centerOnCanvasPoint:(CGPoint)point
{
    NSScrollView *scrollView = [self enclosingScrollView];

    CGRect clipViewFrame = [[scrollView contentView] frame];

    CGFloat scale = [[self window] backingScaleFactor];
    if (!scale) scale = 1;
    
    CGFloat m = (_magnification / scale);
    point.x *= m;
    point.y *= m;

    point.x -= NSWidth( clipViewFrame) / 2.0;
    point.y -= NSHeight(clipViewFrame) / 2.0;
        
    [self scrollPoint:point];
}


- (void) _pinOnCanvasPoint:(CGPoint)point
{
    CGPoint pointUnderMouse;

    if ([self convertMouseLocationToCanvasPoint:&pointUnderMouse]) {
        CGPoint delta = CGPointMake(
            point.x - pointUnderMouse.x,
            point.y - pointUnderMouse.y
        );

        CGFloat scale = [[self window] backingScaleFactor];
        if (!scale) scale = 1;

        CGFloat m = (_magnification / scale);
        delta.x *= m;
        delta.y *= m;
        
        CGPoint origin = [self visibleRect].origin;
        origin.x += delta.x;
        origin.y += delta.y;

        [self scrollPoint:origin];
    }
}


#pragma mark - Magnification

- (void) setMagnification:(CGFloat)magnification pinnedAtCanvasPoint:(NSPoint)point
{
    if (_magnification != magnification) {
        [self setMagnification:magnification];
        [self _pinOnCanvasPoint:point];
    }
}


- (void) setMagnification:(CGFloat)magnification centeredAtCanvasPoint:(NSPoint)point
{
    if (_magnification != magnification) {
        [self setMagnification:magnification];
        [self _centerOnCanvasPoint:point];
    }
}


- (void) setMagnification:(CGFloat)magnification
{
    if (_magnification != magnification) {
        _magnification = magnification;
        [self sizeToFit];
        [self setNeedsLayout];
        [self invalidateCursors];
    }
}


#pragma mark - Public Methods

- (void) sizeToFit
{
    CGSize size = [_canvas size];

    CGFloat scale = [[self window] backingScaleFactor];
    if (!scale) scale = 1;

    CGFloat m = (_magnification / scale);
    size.width  *= m;
    size.height *= m;

    [self setFrame:CGRectMake(0, 0, size.width, size.height)];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    for (MeasurementLabel *label in _measurementLabels) {
        [label updateText];
    }

    [self setNeedsLayout];
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
    
    _needsObjectViewReorder = YES;

    [self addSubview:view];

    if ([view measurementLabelStyle] != MeasurementLabelStyleNone) {
        if (!_measurementLabels) {
            _measurementLabels = [NSMutableArray array];
        }
        
        if (!_GUIDToMeasurementLabelMap) {
            _GUIDToMeasurementLabelMap = [[NSMutableDictionary alloc] init];
        }

        MeasurementLabel *label = [[MeasurementLabel alloc] initWithFrame:CGRectZero];
        [label setOwningObjectView:view];
        [label setHidden:[view isMeasurementLabelHidden]];
        [label setTranslatesAutoresizingMaskIntoConstraints:NO];

        [_measurementLabels addObject:label];

        NSString *GUID = [[view canvasObject] GUID];
        [_GUIDToMeasurementLabelMap setObject:label forKey:GUID];

        [self addSubview:label];
    }
}


- (void) removeCanvasObjectView:(CanvasObjectView *)view
{
    NSString *GUID = [[view canvasObject] GUID];
    MeasurementLabel *label = [_GUIDToMeasurementLabelMap objectForKey:GUID];
    
    if (label) {
        [label removeFromSuperview];
    }

    [view removeFromSuperview];
    [_canvasObjectViews removeObject:view];
}


- (void) updateCanvasObjectView:(CanvasObjectView *)view
{
    NSString *GUID = [[view canvasObject] GUID];
    MeasurementLabel *label = [_GUIDToMeasurementLabelMap objectForKey:GUID];

    [self setNeedsLayout];

    [label updateText];
}


- (void) makeVisibleAndPopInLabelForView:(CanvasObjectView *)view
{
    NSString *GUID = [[view canvasObject] GUID];
    MeasurementLabel *label = [_GUIDToMeasurementLabelMap objectForKey:GUID];

    [label setHidden:NO];
    [label doPopInAnimationWithDuration:0.25];
    
    [_delegate canvasView:self didFinalizeNewbornWithView:view];
}



- (CanvasObjectView *) duplicateObjectView:(CanvasObjectView *)objectView
{
    return [_delegate canvasView:self duplicateObjectView:objectView];
}


- (void) objectViewDoubleClick:(CanvasObjectView *)objectView
{
    [_delegate canvasView:self objectViewDoubleClick:objectView];
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

- (BOOL) isOpaque
{
    return YES;
}


@end
