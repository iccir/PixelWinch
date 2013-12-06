//
//  ResizeKnobLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "ResizeKnobView.h"

#import "Canvas.h"
#import "CanvasObjectView.h"
#import "CanvasObject.h"
#import "CursorAdditions.h"
#import "WeakTargetActionPair.h"

static const CGFloat sPaddingForShadow = 8;
static const CGFloat sBorderWidth = 2;

@implementation ResizeKnobView {
    CALayer *_sublayer;
    CGRect   _rectForResize;
    CGPoint  _downMousePoint;
}


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _sublayer = [CALayer layer];

        [[self layer] addSublayer:_sublayer];
        [_sublayer setDelegate:self];
        [_sublayer setNeedsDisplay];

        [self setNeedsLayout];
    }

    return self;
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == _sublayer) {
        XUIGraphicsPushContext(context);

        NSColor *borderColor = [NSColor whiteColor];
        NSColor *fillColor   = [NSColor blackColor];

        CGRect rect = CGRectInset([_sublayer bounds], sPaddingForShadow, sPaddingForShadow);

        CGContextSaveGState(context);

        // Shadow
        if (_highlighted) {
            NSColor *shadowColor = [NSColor blueColor];
            fillColor = shadowColor;

            [borderColor set];

            CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 8, [shadowColor CGColor]);
            CGContextFillEllipseInRect(context, rect);

            CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 4, [shadowColor CGColor]);
            CGContextFillEllipseInRect(context, rect);

        } else {
            NSColor *shadowColor = [NSColor blackColor];
            shadowColor = [shadowColor colorWithAlphaComponent:0.5];
            CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 2, [shadowColor CGColor]);

            [borderColor set];
            CGContextFillEllipseInRect(context, rect);
        }
        
        CGContextRestoreGState(context);
        
        rect = CGRectInset(rect, sBorderWidth, sBorderWidth);

        [fillColor set];
        CGContextFillEllipseInRect(context, rect);
        
        
        XUIGraphicsPopContext();
    }
}

- (BOOL) layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window
{
    [[self layer] setContentsScale:newScale];
    [_sublayer setContentsScale:newScale];
    [_sublayer setNeedsDisplay];

    return YES;
}


- (void) layoutSubviews
{
    CGRect frame = [self bounds];
    [_sublayer setFrame:CGRectInset(frame, -sPaddingForShadow, -sPaddingForShadow)];
}


- (NSInteger) canvasOrder
{
    return CanvasOrderResizeKnob;
}


- (NSCursor *) cursor
{
    if (_edge == ObjectEdgeTop || _edge == ObjectEdgeBottom) {
        return [NSCursor winch_resizeNorthSouthCursor];

    } else if (_edge == ObjectEdgeLeft || _edge == ObjectEdgeRight) {
        return [NSCursor winch_resizeEastWestCursor];

    } else if (_edge == ObjectEdgeTopLeft || _edge == ObjectEdgeBottomRight) {
        return [NSCursor winch_resizeNorthWestSouthEastCursor];

    } else if (_edge == ObjectEdgeTopRight || _edge == ObjectEdgeBottomLeft) {
        return [NSCursor winch_resizeNorthEastSouthWestCursor];
    }

    return nil;
}


- (CGRect) rectForCanvasLayout
{
    CGRect rect = [[self owningObjectView] rectForCanvasLayout];
    
    if (_edge == ObjectEdgeTopLeft || _edge == ObjectEdgeLeft || _edge == ObjectEdgeBottomLeft) {
        rect.origin.x = CGRectGetMinX(rect);
    } else if (_edge == ObjectEdgeTopRight || _edge == ObjectEdgeRight || _edge == ObjectEdgeBottomRight) {
        rect.origin.x = CGRectGetMaxX(rect);
    } else {
        rect.origin.x = CGRectGetMidX(rect);
    }

    if (_edge == ObjectEdgeTopLeft || _edge == ObjectEdgeTop || _edge == ObjectEdgeTopRight) {
        rect.origin.y = CGRectGetMinY(rect);
    } else if (_edge == ObjectEdgeBottomLeft || _edge == ObjectEdgeBottom || _edge == ObjectEdgeBottomRight) {
        rect.origin.y = CGRectGetMaxY(rect);
    } else {
        rect.origin.y = CGRectGetMidY(rect);
    }

    rect.size = CGSizeZero;

    return rect;
}


- (XUIEdgeInsets) paddingForCanvasLayout
{
    const CGFloat sKnobPadding = 5;
    return XUIEdgeInsetsMake(sKnobPadding, sKnobPadding, sKnobPadding, sKnobPadding);
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _downMousePoint = [event locationInWindow];
    CanvasObject *object = [[self owningObjectView] canvasObject];
    _rectForResize = [object rect];
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CGPoint currentMousePoint = [event locationInWindow];

    CGPoint deltaMousePoint = CGPointMake(
        _downMousePoint.x - currentMousePoint.x,
        _downMousePoint.y - currentMousePoint.y
    );
   
    CGPoint deltaPoint = [[self canvasView] roundedCanvasPointForPoint:deltaMousePoint];
    
    CanvasObject *object = [[self owningObjectView] canvasObject];

    CGRect rect = _rectForResize;

    if (_edge == ObjectEdgeTopLeft || _edge == ObjectEdgeLeft || _edge == ObjectEdgeBottomLeft) {
        rect.origin.x -= deltaPoint.x;
        rect.size.width += deltaPoint.x;
    } else if (_edge == ObjectEdgeTopRight || _edge == ObjectEdgeRight || _edge == ObjectEdgeBottomRight) {
        rect.size.width -= deltaPoint.x;
    }
    
    if (_edge == ObjectEdgeTopLeft || _edge == ObjectEdgeTop || _edge == ObjectEdgeTopRight) {
        rect.origin.y += deltaPoint.y;
        rect.size.height -= deltaPoint.y;
    } else if (_edge == ObjectEdgeBottomLeft || _edge == ObjectEdgeBottom || _edge == ObjectEdgeBottomRight) {
        rect.size.height += deltaPoint.y;
    }
    
    [object setRect:rect];
}


- (void) setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        [_sublayer setNeedsDisplay];
    }
}

@end
