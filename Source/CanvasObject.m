//
//  CanvasObject.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "CanvasObject.h"

@implementation CanvasObject

- (id) init
{
    if ((self = [super init])) {
        _GUID = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), [[NSUUID UUID] UUIDString]];
    }

    return self;
}

- (void) moveEdge:(CGRectEdge)edge value:(CGFloat)value
{
    // Subclasses to implement
}


@end
