// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "LineTool.h"

#import "Canvas.h"
#import "CursorAdditions.h"

#import "Line.h"
#import "LineObjectView.h"

typedef NS_ENUM(NSInteger, LineDirection) {
    LineDirectionNone,

    LineDirectionUp,
    LineDirectionDown,
    LineDirectionLeft,
    LineDirectionRight
};


@implementation LineTool {
    Line   *_newLine;
    CGPoint _downPoint;
    CGPoint _originalPoint;
    LineDirection _lineDirection;
}


- (NSCursor *) cursor
{
    return [NSCursor crosshairCursor];
}


- (NSString *) name
{
    return @"line";
}


- (unichar) shortcutKey
{
    return 'l';
}


- (BOOL) canSelectCanvasObject:(CanvasObject *)object
{
    return [object isKindOfClass:[Line class]];
}


- (void) flagsChangedWithEvent:(NSEvent *)event
{

}


- (CGPoint) _canvasPointForEvent:(NSEvent *)event
{
    return [[[self owner] canvasView] canvasPointForEvent:event];
}


- (void) _updateNewLineWithEvent:(NSEvent *)event
{
    CGPoint currentPoint = [self _canvasPointForEvent:event];
    CGPoint startPoint   = _originalPoint;
    CGRect  rect         = CGRectZero;
    
    CGPoint deltaPoint = CGPointMake(
        currentPoint.x - _originalPoint.x,
        currentPoint.y - _originalPoint.y
    );

    LineDirection direction = LineDirectionNone;
    
    if (fabs(deltaPoint.x) > fabs(deltaPoint.y)) {
        rect.origin.y = floor(startPoint.y);
        rect.size.height = 1;

        if (deltaPoint.x < 0) {
            direction = LineDirectionLeft;
            rect.origin.x = ceil(startPoint.x);
            rect.size.width = floor(currentPoint.x) - rect.origin.x;

        } else if (deltaPoint.x > 0) {
            direction = LineDirectionRight;
            rect.origin.x = floor(startPoint.x);
            rect.size.width = ceil(currentPoint.x) - rect.origin.x;
        }

    } else {
        rect.origin.x = floor(startPoint.x);
        rect.size.width = 1;

        if (deltaPoint.y < 0) {
            direction = LineDirectionUp;
            rect.origin.y = ceil(startPoint.y);
            rect.size.height = floor(currentPoint.y) - rect.origin.y;
            
        } else if (deltaPoint.y > 0) {
            direction = LineDirectionDown;
            rect.origin.y = floor(startPoint.y);
            rect.size.height = ceil(currentPoint.y) - rect.origin.y;
        }
    }
    
    if (_lineDirection != direction) {
        _lineDirection = direction;

        // Remove/cleanup existing view
        CanvasObjectView *view = [[self owner] viewForCanvasObject:_newLine];
        [view endTrackingWithEvent:event point:[self _canvasPointForEvent:event]];

        [[[self owner] canvas] removeCanvasObject:_newLine];
        _newLine = nil;
    }

    if (direction == LineDirectionNone) {
        return;
    }

    rect = CGRectStandardize(rect);

    if (!_newLine) {
        BOOL vertical = (direction == LineDirectionUp) || (direction == LineDirectionDown);
        _newLine = [Line lineVertical:vertical];
        
        [[[self owner] canvas] addCanvasObject:_newLine];
        
        CanvasObjectView *view = [[self owner] viewForCanvasObject:_newLine];
        [view startTrackingWithEvent:event point:rect.origin];
        [view setNewborn:YES];
    }

    [_newLine setRect:rect];

    NSString *cursorText = GetStringForFloat([_newLine length]);
    [[CursorInfo sharedInstance] setText:cursorText forKey:@"new-line"];
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    _downPoint     = [event locationInWindow];
    _originalPoint = [self _canvasPointForEvent:event];
    _lineDirection = LineDirectionNone;
    
    return YES;
}


- (void) mouseDraggedWithEvent:(NSEvent *)event
{
    [self _updateNewLineWithEvent:event];
}


- (void) mouseUpWithEvent:(NSEvent *)event
{
    [self _updateNewLineWithEvent:event];

    CanvasObjectView *view = [[self owner] viewForCanvasObject:_newLine];
    [view endTrackingWithEvent:event point:[self _canvasPointForEvent:event]];
    [view setNewborn:NO];

    [[CursorInfo sharedInstance] setText:nil forKey:@"new-line"];

    _newLine = nil;
    _lineDirection = LineDirectionNone;
}


@end
