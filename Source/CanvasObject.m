//
//  CanvasObject.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "CanvasObject.h"
#import "Canvas.h"

@implementation CanvasObject {
    CGRect _rect;
}

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    self = nil;
    return nil;
}


- (id) init
{
    if ((self = [super init])) {
        _GUID = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), [[NSUUID UUID] UUIDString]];
    }

    return self;
}


- (NSDictionary *) dictionaryRepresentation
{
    return @{ };
}


#pragma mark - Accessors

- (void) setRect:(CGRect)rect
{
    @synchronized(self) {
        if (!CGRectEqualToRect(_rect, rect)) {
            _rect = CGRectStandardize(rect);
            [[self canvas] objectDidUpdate:self];
        }
    }
}


- (CGRect) rect
{
    @synchronized(self) {
        return _rect;
    }
}


- (void) setOriginX:(CGFloat)originX
{
    @synchronized(self) {
        CGRect rect = [self rect];
        rect.origin.x = originX;
        [self setRect:rect];
    }
}


- (void) setOriginY:(CGFloat)originY
{
    @synchronized(self) {
        CGRect rect = [self rect];
        rect.origin.y = originY;
        [self setRect:rect];
    }
}


- (void) setSizeWidth:(CGFloat)sizeWidth
{
    @synchronized(self) {
        CGRect rect = [self rect];
        rect.size.width = sizeWidth;
        [self setRect:rect];
    }
}


- (void) setSizeHeight:(CGFloat)sizeHeight
{
    @synchronized(self) {
        CGRect rect = [self rect];
        rect.size.height = sizeHeight;
        [self setRect:rect];
    }
}


- (CGFloat) originX    { @synchronized(self) { return _rect.origin.x;    } }
- (CGFloat) originY    { @synchronized(self) { return _rect.origin.y;    } }
- (CGFloat) sizeWidth  { @synchronized(self) { return _rect.size.width;  } }
- (CGFloat) sizeHeight { @synchronized(self) { return _rect.size.height; } }


@end
