// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
