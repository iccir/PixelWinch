
//
//  RectangleLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "RectangleObjectView.h"
#import "Rectangle.h"
#import "TextLayer.h"

#import <objc/objc-runtime.h>

@implementation RectangleObjectView {
    CALayer   *_sublayer;
    TextLayer *_textLayer;
    CGPoint    _downPoint;
}

@dynamic rectangle;


- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _sublayer = [CALayer layer];
        [_sublayer setDelegate:self];
        [[self layer] addSublayer:_sublayer];
        
        _textLayer = [TextLayer layer];
        [_textLayer setDelegate:self];
        [[self layer] addSublayer:_textLayer];

        [self _updateLayers];
    }

    return self;
}


- (CGRect) rectForCanvasLayout
{
    return [[self rectangle] rect];
}


- (NSCursor *) cursor
{
    return [NSCursor arrowCursor];
}


- (NSArray *) resizeKnobTypes
{
    return @[
        @( ResizeKnobTopLeft     ),
        @( ResizeKnobTop         ),
        @( ResizeKnobTopRight    ),
        @( ResizeKnobLeft        ),
        @( ResizeKnobRight       ),
        @( ResizeKnobBottomLeft  ),
        @( ResizeKnobBottom      ),
        @( ResizeKnobBottomRight )
    ];
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        _downPoint = point;
        [[self rectangle] setRect:CGRectMake(_downPoint.x, _downPoint.y, 0, 0)];
    } else {
        [super startTrackingWithEvent:event point:point];
    }
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        CGFloat deltaX = point.x - _downPoint.x;
        CGFloat deltaY = point.y - _downPoint.y;

        Rectangle *rectangle = [self rectangle];

        [rectangle setRect:CGRectMake(_downPoint.x, _downPoint.y, deltaX, deltaY)];
    
        CursorInfo *cursorInfo = [CursorInfo sharedInstance];
        
        CGSize size = CGSizeMake(fabs(deltaX), fabs(deltaY));
        [cursorInfo setText:GetStringForSize(size) forKey:@"new-rectangle"];
        
    } else {
        [super continueTrackingWithEvent:event point:point];
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if ([self isNewborn]) {
        [[CursorInfo sharedInstance] setText:nil forKey:@"new-rectangle"];
        AddPopInAnimation(_textLayer, 0.25);
    } else {
        [super endTrackingWithEvent:event point:point];
    }
}


- (void) layoutSubviews
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
