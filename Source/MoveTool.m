//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "MoveTool.h"
#import "Canvas.h"


@implementation MoveTool

- (NSCursor *) cursor
{
    return [NSCursor arrowCursor];
}


- (NSString *) name
{
    return @"move";
}


- (unichar) shortcutKey
{
    return 'v';
}


- (BOOL) canSelectCanvasObject:(CanvasObject *)object
{
    return YES;
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    [[[self owner] canvas] deselectAllObjects];
    return NO;
}


@end
