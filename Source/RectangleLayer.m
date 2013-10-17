//
//  RectangleLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "RectangleLayer.h"
#import "Rectangle.h"
#import "TextLayer.h"

#import <objc/objc-runtime.h>

@implementation RectangleLayer {
    CALayer   *_sublayer;
    TextLayer *_textLayer;
    CGPoint    _downPoint;
    CGPoint    _originPoint;
}

@dynamic rectangle;


- (id) init
{
    if (self = [super init]) {
        _sublayer = [CALayer layer];
        [_sublayer setDelegate:self];
        [self addSublayer:_sublayer];
        
        _textLayer = [TextLayer layer];
        [_textLayer setDelegate:self];
        [self addSublayer:_textLayer];

        [self _updateLayers];
    }

    return self;
}


- (CGRect) rectForCanvasLayout
{
    return [[self rectangle] rect];
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _downPoint = point;
    
    Rectangle *rectangle = [self rectangle];
    _originPoint = rectangle ? [rectangle rect].origin : NSZeroPoint;

    return YES;
}


- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    CGFloat deltaX = point.x - _downPoint.x;
    CGFloat deltaY = point.y - _downPoint.y;

    Rectangle *rectangle = [self rectangle];

    if ([self isNewborn]) {
        [rectangle setRect:CGRectMake(_downPoint.x, _downPoint.y, deltaX, deltaY)];
    
        CursorInfo *cursorInfo = [CursorInfo sharedInstance];
        
        [cursorInfo setText:GetStringForSize(CGSizeMake(deltaX, deltaY)) forKey:@"new-rectangle"];
        
    } else {
        CGRect rect = [rectangle rect];
        rect.origin.x = _originPoint.x + deltaX;
        rect.origin.y = _originPoint.y + deltaY;
        
        [[self rectangle] setRect:rect];
    }
}


- (void) mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point
{
    [[CursorInfo sharedInstance] setText:nil forKey:@"new-rectangle"];

    if ([self isNewborn]) {
        AddPopInAnimation(_textLayer, 0.25);
    }
}


- (void) layoutSublayers
{
    [_sublayer setFrame:[self bounds]];

    [_textLayer setFrame:[self bounds]];
    [_textLayer setDimensions:[[self rectangle] rect].size];
}



- (void) _updateLayers
{
    Preferences *preferences = [Preferences sharedInstance];

    [_sublayer setBackgroundColor:[[preferences placedRectangleFillColor] CGColor]];
    [_sublayer setBorderColor:[[preferences placedRectangleBorderColor] CGColor]];
    [_sublayer setBorderWidth:0.5];
}


- (void) preferencesDidChange:(Preferences *)preferences
{
    [self _updateLayers];
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


- (void) setNewborn:(BOOL)newborn
{
    [super setNewborn:newborn];
    [_textLayer setHidden:newborn];
}


@end
