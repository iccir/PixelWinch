//
//  HandTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "HandTool.h"
#import "CanvasView.h"
#import "CanvasObjectView.h"


@implementation HandTool {
    NSPoint  _handEventStartPoint;
    NSPoint  _handCanvasStartPoint;
}


- (NSCursor *) cursor
{
    return _active ? [NSCursor closedHandCursor] : [NSCursor openHandCursor];
}


- (NSString *) name
{
    return @"hand";
}


- (unichar) shortcutKey
{
    return 'h';
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    NSScrollView *scrollView = [[[self owner] canvasView] enclosingScrollView];

    [self setActive:YES];
    _handEventStartPoint  = [event locationInWindow];
    _handCanvasStartPoint = [[scrollView documentView] visibleRect].origin;

    return YES;
}


- (void) mouseDraggedWithEvent:(NSEvent *)event
{
    NSPoint eventCurrentPoint = [event locationInWindow];

    NSPoint movedPoint = NSMakePoint(
        _handCanvasStartPoint.x - (eventCurrentPoint.x - _handEventStartPoint.x),
        _handCanvasStartPoint.y + (eventCurrentPoint.y - _handEventStartPoint.y)
    );

    NSScrollView *scrollView = [[[self owner] canvasView] enclosingScrollView];
    
    NSRect rect = NSZeroRect;
    rect.origin = movedPoint;
    rect = [[scrollView contentView] constrainBoundsRect:rect];
    movedPoint = rect.origin;
    
    [[scrollView contentView] scrollToPoint:movedPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}


- (void) mouseUpWithEvent:(NSEvent *)event
{
    [self setActive:NO];
}

@end
