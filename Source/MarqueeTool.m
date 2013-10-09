//
//  MarqueeTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "MarqueeTool.h"

@implementation MarqueeTool

- (ToolType) type { return ToolTypeMarquee; }

- (NSCursor *) cursor
{
    return [NSCursor crosshairCursor];
}

@end
