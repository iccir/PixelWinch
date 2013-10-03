//
//  CanvasRulerView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import "RulerView.h"

@implementation RulerView

- (void) drawRect:(NSRect)dirtyRect
{
    [[NSColor blueColor] set];

    [NSBezierPath fillRect:dirtyRect];
}


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        return;
    }

    if ([_delegate rulerView:self mouseDownWithEvent:event]) {
        while (1) {
            event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            
            NSEventType type = [event type];
            if (type == NSLeftMouseUp) {
                [_delegate rulerView:self mouseUpWithEvent:event];
                break;

            } else if (type == NSLeftMouseDragged) {
                [_delegate rulerView:self mouseDragWithEvent:event];
            }
        }
    }
}

@end
