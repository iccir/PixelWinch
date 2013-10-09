//
//  CaptureView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-07.
//
//

#import "CaptureView.h"

@implementation CaptureView {
    CGImageRef _image;
    CALayer *_selectionLayer;
    BOOL _shouldCancel;
}

- (id) initWithImage:(CGImageRef)image
{
    if ((self = [super initWithFrame:CGRectZero])) {
        _image = CGImageRetain(image);

        [self setWantsLayer:YES];
        [[self layer] setContents:(__bridge id)_image];
        
        _selectionLayer = [CALayer layer];
        [_selectionLayer setDelegate:self];
        
        [_selectionLayer setBackgroundColor:[[NSColor redColor] CGColor]];
        [[self layer] addSublayer:_selectionLayer];
    }
    
    return self;
}

- (void) dealloc
{
    CGImageRelease(_image);
}


- (void) resetCursorRects
{
    [self addCursorRect:[self bounds] cursor:[NSCursor crosshairCursor]];
}


- (void) _updateRect:(NSRect)rect
{
    [_selectionLayer setFrame:rect];
}



- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        return;
    }

    NSPoint location;
    
    location = [event locationInWindow];
    location = [[[self window] contentView] convertPoint:location toView:self];

    NSPoint startLocation = location;
    NSRect  rect;

    while (!_shouldCancel) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];

        location = [event locationInWindow];
        location = [[[self window] contentView] convertPoint:location toView:self];
        
        rect = NSMakeRect(startLocation.x, startLocation.y, 0, 0);
        rect.size.width  = location.x - startLocation.x;
        rect.size.height = location.y - startLocation.y;
        
        [self _updateRect:rect];
        
        if ([event type] == NSLeftMouseUp) {
            break;
        }
    }
    
    if (!_shouldCancel) {
        [_delegate captureView:self didCaptureRect:rect];
    }
}


@end
