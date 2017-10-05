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


@interface ResizeKnobView () <CALayerDelegate>
@end


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
        ResizeKnobStyle style = [[self owningObjectView] resizeKnobStyle];
        
        PushGraphicsContext(context);

        NSColor *borderColor = [NSColor whiteColor];
        NSColor *fillColor   = [NSColor blackColor];

        CGRect rect = CGRectInset([_sublayer bounds], sPaddingForShadow, sPaddingForShadow);
        NSBezierPath *outerPath;
        NSBezierPath *innerPath;

        if (style == ResizeKnobStyleCircular) {
            outerPath = [NSBezierPath bezierPathWithOvalInRect:rect];

            CGRect innerRect = CGRectInset(rect, sBorderWidth, sBorderWidth);
            
            if (!CGRectIsEmpty(innerRect)) {
                innerPath = [NSBezierPath bezierPathWithOvalInRect:innerRect];
            }

        } else if (style == ResizeKnobStyleRectangular && (_edge == ObjectEdgeLeft || _edge == ObjectEdgeRight)) {
            CGFloat centerX = CGRectGetMidX(rect);

            CGRect knobRect = CGRectMake(0, 0, 3, 11);
            knobRect.origin.y = rect.origin.y + ((rect.size.height - knobRect.size.height) / 2);

            if (_edge == ObjectEdgeLeft) {
                knobRect.origin.x = centerX;
            } else {
                knobRect.origin.x = centerX - knobRect.size.width;
            }
            
            outerPath = [NSBezierPath bezierPathWithRect:knobRect];

            CGRect innerRect = CGRectInset(knobRect, 1, 1);
            
            if (!CGRectIsEmpty(knobRect)) {
                innerPath = [NSBezierPath bezierPathWithRect:innerRect];
            }
            
        } else if (style == ResizeKnobStyleRectangular && (_edge == ObjectEdgeTop || _edge == ObjectEdgeBottom)) {
            CGFloat centerY = CGRectGetMidY(rect);

            CGRect knobRect = CGRectMake(0, 0, 11, 3);
            knobRect.origin.x = rect.origin.x + ((rect.size.width - knobRect.size.width) / 2);

            if (_edge == ObjectEdgeTop) {
                knobRect.origin.y = centerY;
            } else {
                knobRect.origin.y = centerY - knobRect.size.height;
            }
            
            outerPath = [NSBezierPath bezierPathWithRect:knobRect];
            
            CGRect innerRect = CGRectInset(knobRect, 1, 1);

            if (!CGRectIsEmpty(knobRect)) {
                innerPath = [NSBezierPath bezierPathWithRect:innerRect];
            }
        }

        CGContextSaveGState(context);

        if (outerPath) {
            if (_highlighted) {
                NSColor *shadowColor = [NSColor blueColor];

                borderColor = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:1.0 alpha:1.0];
                fillColor   = [NSColor colorWithCalibratedRed:0   green:0   blue:1.0 alpha:1.0];

                [borderColor set];
                CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 4, [shadowColor CGColor]);
                [outerPath fill];

            } else {
                [borderColor set];
                [outerPath fill];
            }
        }

        CGContextRestoreGState(context);

        if (innerPath) {
            [fillColor set];
            [innerPath fill];
        }
        
        PopGraphicsContext();
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


- (NSEdgeInsets) paddingForCanvasLayout
{
    const CGFloat sKnobPadding = 5;
    return NSEdgeInsetsMake(sKnobPadding, sKnobPadding, sKnobPadding, sKnobPadding);
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _downMousePoint = [event locationInWindow];
    CanvasObject *object = [[self owningObjectView] canvasObject];
    _rectForResize = [object rect];
    
    if ([[self owningObjectView] resizeKnobStyle] == ResizeKnobStyleRectangular) {
        [self _hideKnobAnimated:YES];
        [NSCursor hide];
    }
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


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([[self owningObjectView] resizeKnobStyle] == ResizeKnobStyleRectangular) {
        [self _unhideKnob];
        [NSCursor unhide];
    }
}

#pragma mark - Show/Hide Logic

- (void) _hideKnobAnimated:(BOOL)animated
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setAllowsImplicitAnimation:YES];
        if (!animated) [context setDuration:0.0];
        [self setAlphaValue:0.0];
    } completionHandler:nil];
}


- (void) _unhideKnob
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setAllowsImplicitAnimation:YES];
        [self setAlphaValue:1.0];
    } completionHandler:nil];
}


- (void) hideMomentarily
{
    [self _hideKnobAnimated:NO];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_unhideKnob) object:nil];
    [self performSelector:@selector(_unhideKnob) withObject:nil afterDelay:1.0];
}


- (void) willSnapshot { [self setHidden:YES]; }
- (void) didSnapshot  { [self setHidden:NO];  }


#pragma mark - Accessors

- (void) setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted) {
        _highlighted = highlighted;
        [_sublayer setNeedsDisplay];
    }
}

@end
