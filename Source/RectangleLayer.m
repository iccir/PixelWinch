//
//  RectangleLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "RectangleLayer.h"
#import "Rectangle.h"


@implementation RectangleLayer {
    CALayer *_sublayer;
}

@dynamic rectangle;


- (id) init
{
    if (self = [super init]) {
        _sublayer = [CALayer layer];
        [_sublayer setDelegate:self];
        [self addSublayer:_sublayer];
    }

    return self;
}


- (CGRect) rectForCanvasLayout
{
    return [[self rectangle] rect];
}


- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    Rectangle *rectangle = [self rectangle];
    CGRect rect = [rectangle rect];
    
    rect.size.width  = point.x - rect.origin.x;
    rect.size.height = point.y - rect.origin.y;
    
    [rectangle setRect:rect];
}


- (void) layoutSublayers
{
    [_sublayer setFrame:[self bounds]];
    [_sublayer setBackgroundColor:[[NSColor colorWithCalibratedRed:0 green:0 blue:0.33 alpha:0.25] CGColor]];
    [_sublayer setBorderColor:[[NSColor whiteColor] CGColor]];
    [_sublayer setBorderWidth:0.5];
}


- (void) preferencesDidChange:(Preferences *)preferences
{
    [_sublayer setBackgroundColor:[[preferences placedRectangleFillColor] CGColor]];
    [_sublayer setBorderColor:[[preferences placedRectangleBorderColor] CGColor]];
}


#pragma - Accessors

- (void) setRectangle:(Rectangle *)rectangle
{
    [self setCanvasObject:rectangle];
}


- (Rectangle *) rectangle
{
    return (Rectangle *)[self canvasObject];
}


@end
