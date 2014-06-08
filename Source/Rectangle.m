
//
//  Rectangle.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Rectangle.h"
#import "Canvas.h"

@implementation Rectangle

+ (NSString *) groupName
{
    return @"rectangles";
}


+ (instancetype) rectangle
{
    return [[self alloc] init];
}


- (id) duplicate
{
    Rectangle *result = [[Rectangle alloc] init];
    [result setRect:[self rect]];
    return result;
}


- (BOOL) isValid
{
    CGSize size = [self rect].size;
    return size.width > 0 || size.height > 0;
}


- (BOOL) writeToPasteboard:(NSPasteboard *)pasteboard
{
    CGSize size = [self rect].size;
    [pasteboard writeObjects:@[ GetPasteboardStringForSize(size) ]];
    return YES;
}


- (BOOL) isSelectable
{
    return YES;
}


@end
