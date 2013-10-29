//
//  MoveTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "MoveTool.h"

@implementation MoveTool

- (ToolType) type { return ToolTypeMove; }


- (NSCursor *) cursor
{
    return [NSCursor arrowCursor];
}


@end
