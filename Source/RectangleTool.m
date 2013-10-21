//
//  RectangleTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "RectangleTool.h"

@implementation RectangleTool

- (ToolType) type { return ToolTypeRectangle; }

- (NSCursor *) cursor
{
    return [NSCursor crosshairCursor];
}

@end
