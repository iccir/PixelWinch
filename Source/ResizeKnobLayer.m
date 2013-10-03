//
//  ResizeKnobLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "ResizeKnobLayer.h"
#import "CanvasObject.h"
#import "CursorAdditions.h"


@implementation ResizeKnobLayer {
    CALayer *_sublayer;
}


- (id) init
{
    if ((self = [super init])) {
        _sublayer = [CALayer layer];

        [_sublayer setDelegate:self];
        [_sublayer setBackgroundColor:[[NSColor blackColor] CGColor]];
        [_sublayer setCornerRadius:4];
        [_sublayer setBorderColor:[[NSColor whiteColor] CGColor]];
        [_sublayer setBorderWidth:2];
        
        [_sublayer setShadowOpacity:0.5];
        [_sublayer setShadowRadius:1];
        [_sublayer setShadowOffset:CGSizeMake(0, 1)];
    
        [self addSublayer:_sublayer];
    }

    return self;
}


- (void) layoutSublayers
{
    [_sublayer setFrame:[self bounds]];
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
    CGRect rect = [[self parentLayer] rectForCanvasLayout];
    
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

- (NSEdgeInsets) paddingForCanvasLayout
{
    return NSEdgeInsetsMake(4, 4, 4, 4);
}

- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CanvasObject *object = [[self parentLayer] canvasObject];

    if (_type == ResizeKnobTopLeft || _type == ResizeKnobLeft || _type == ResizeKnobBottomLeft) {
        [object moveEdge:CGRectMinXEdge value:point.x];
    } else if (_type == ResizeKnobTopRight || _type == ResizeKnobRight || _type == ResizeKnobBottomRight) {
        [object moveEdge:CGRectMaxXEdge value:point.x];
    }
    
    if (_type == ResizeKnobTopLeft || _type == ResizeKnobTop || _type == ResizeKnobTopRight) {
        [object moveEdge:CGRectMinYEdge value:point.y];
    } else if (_type == ResizeKnobBottomLeft || _type == ResizeKnobBottom || _type == ResizeKnobBottomRight) {
        [object moveEdge:CGRectMaxYEdge value:point.y];
    }
}


@end
