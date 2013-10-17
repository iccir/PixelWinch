//
//  Marquee.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Marquee.h"
#import "Canvas.h"


@implementation Marquee

- (BOOL) isValid
{
    CGSize size = [self rect].size;
    return size.width > 0 || size.height > 0;
}


@end
