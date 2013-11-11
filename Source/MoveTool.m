//
//  MoveTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

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
    [[[self owner] canvas] unselectAllObjects];
    return NO;
}


@end
