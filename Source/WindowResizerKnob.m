//  (c) 2015-2018, Ricci Adams.  All rights reserved.


#import "WindowResizerKnob.h"

@implementation WindowResizerKnob {
    NSTrackingArea *_trackingArea;
}


- (id) initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
        [self _commonWindowResizerKnobInit];
    }

    return self;
}


- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self _commonWindowResizerKnobInit];
    }
    
    return self;
}


- (void) dealloc
{
    [self removeTrackingArea:_trackingArea];
    _trackingArea = nil;
}


- (void) drawRect:(NSRect)dirtyRect
{
    NSImage *image = [NSImage imageNamed:@"WindowResizer"];
    
    CGRect bounds = [self bounds];
    
    CGSize imageSize = [image size];
    CGRect imageRect = { CGPointZero, imageSize };

    imageRect.origin.x = bounds.size.width - imageSize.width;
    imageRect.origin.y = 0;
    
    [image drawInRect:imageRect];
}


- (void) _commonWindowResizerKnobInit
{
	[self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];

    NSTrackingAreaOptions options = NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow|NSTrackingCursorUpdate;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:options owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSEventTypeLeftMouseDown) {
        return;
    }

    NSWindow *window = [self window];
    id<WindowResizerKnobDelegate> delegate = _delegate;

    NSPoint (^getScreenLocation)(NSEvent *) = ^(NSEvent *e) {
        NSPoint point = [e locationInWindow];
        NSRect  rect = { point, CGSizeZero };
        
        rect = [window convertRectToScreen:rect];
        
        return rect.origin;
    };

    __block NSPoint startPoint = getScreenLocation(event);
    
    void (^dispatchWithEvent)(NSEvent *) = ^(NSEvent *e) {
        NSPoint nowPoint = getScreenLocation(e);
        
        CGFloat xDelta = round(nowPoint.x - startPoint.x);
        CGFloat yDelta = round(nowPoint.y - startPoint.y);
        [delegate windowResizerKnob:self didDragWithDeltaX:xDelta deltaY:yDelta];
    };

    [delegate windowResizerKnobWillStartDrag:self];

    [event locationInWindow];

    while (1) {
        event = [[self window] nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp)];

        NSEventType type = [event type];
        if (type == NSEventTypeLeftMouseUp) {
            dispatchWithEvent(event);
            [delegate windowResizerKnobWillEndDrag:self];
            break;

        } else if (type == NSEventTypeLeftMouseDragged) {
            dispatchWithEvent(event);
        }
    }
    
    [[self window] invalidateCursorRectsForView:self];
}


- (void) cursorUpdate:(NSEvent *)event
{
    [[NSCursor winch_resizeNorthWestSouthEastCursor] set];
}


@end
