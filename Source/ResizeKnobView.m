//
//  ResizeKnobLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "ResizeKnobView.h"

#import "CanvasObjectView.h"
#import "CanvasObject.h"
#import "CursorAdditions.h"


@implementation ResizeKnobView {
    CALayer *_sublayer;
    CGRect   _rectForResize;
    CGPoint  _downMousePoint;
}


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _sublayer = [CALayer layer];

        [_sublayer setDelegate:self];
        [_sublayer setBackgroundColor:[[NSColor blackColor] CGColor]];
        [_sublayer setCornerRadius:4];
        [_sublayer setBorderColor:[[NSColor whiteColor] CGColor]];
        [_sublayer setBorderWidth:2];
        
        [_sublayer setShadowOpacity:0.5];
        [_sublayer setShadowRadius:1];
        [_sublayer setShadowOffset:CGSizeMake(0, 1)];
       
        [[self layer] addSublayer:_sublayer];
    }

    return self;
}


- (void) layoutSubviews
{
    CGRect frame = [self bounds];
    [_sublayer setFrame:CGRectInset(frame, 1, 1)];
}


- (NSInteger) canvasOrder
{
    return CanvasOrderResizeKnob;
}


- (NSCursor *) cursor
{
    if (_type == ResizeKnobTop || _type == ResizeKnobBottom) {
        return [NSCursor winch_resizeNorthSouthCursor];

    } else if (_type == ResizeKnobLeft || _type == ResizeKnobRight) {
        return [NSCursor winch_resizeEastWestCursor];

    } else if (_type == ResizeKnobTopLeft || _type == ResizeKnobBottomRight) {
        return [NSCursor winch_resizeNorthWestSouthEastCursor];

    } else if (_type == ResizeKnobTopRight || _type == ResizeKnobBottomLeft) {
        return [NSCursor winch_resizeNorthEastSouthWestCursor];
    }

    return nil;
}


- (CGRect) rectForCanvasLayout
{
    CGRect rect = [[self owningObjectView] rectForCanvasLayout];
    
    if (_type == ResizeKnobTopLeft || _type == ResizeKnobLeft || _type == ResizeKnobBottomLeft) {
        rect.origin.x = CGRectGetMinX(rect);
    } else if (_type == ResizeKnobTopRight || _type == ResizeKnobRight || _type == ResizeKnobBottomRight) {
        rect.origin.x = CGRectGetMaxX(rect);
    } else {
        rect.origin.x = CGRectGetMidX(rect);
    }

    if (_type == ResizeKnobTopLeft || _type == ResizeKnobTop || _type == ResizeKnobTopRight) {
        rect.origin.y = CGRectGetMinY(rect);
    } else if (_type == ResizeKnobBottomLeft || _type == ResizeKnobBottom || _type == ResizeKnobBottomRight) {
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

    if (_type == ResizeKnobTopLeft || _type == ResizeKnobLeft || _type == ResizeKnobBottomLeft) {
        rect.origin.x -= deltaPoint.x;
        rect.size.width += deltaPoint.x;
    } else if (_type == ResizeKnobTopRight || _type == ResizeKnobRight || _type == ResizeKnobBottomRight) {
        rect.size.width -= deltaPoint.x;
    }
    
    if (_type == ResizeKnobTopLeft || _type == ResizeKnobTop || _type == ResizeKnobTopRight) {
        rect.origin.y += deltaPoint.y;
        rect.size.height -= deltaPoint.y;
    } else if (_type == ResizeKnobBottomLeft || _type == ResizeKnobBottom || _type == ResizeKnobBottomRight) {
        rect.size.height += deltaPoint.y;
    }
    
    [object setRect:rect];
}


@end
