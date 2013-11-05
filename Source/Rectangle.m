
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

+ (instancetype) rectangle
{
    return [[self alloc] init];
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



@end
