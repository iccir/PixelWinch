//
//  GrappleTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "GrappleTool.h"
#import "CursorAdditions.h"


@implementation GrappleTool

- (ToolType) type { return ToolTypeGrapple; }



- (NSCursor *) cursor
{
    return [self calculatedIsVertical] ? [NSCursor winch_grappleVerticalCursor] : [NSCursor winch_grappleHorizontalCursor];
}


- (BOOL) calculatedIsVertical
{
    BOOL isAltPressed = ([NSEvent modifierFlags] & NSAlternateKeyMask) > 0;

    BOOL result = [self isVertical];
    if (isAltPressed) result = !result;

    return result;
}


- (UInt8) calculatedThreshold
{
    UInt8 threshold = ([self tolerance] / 100.0) * 255.0;
    return threshold;
}


@end
