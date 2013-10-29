//
//  CanvasObject.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "CanvasObject.h"
#import "Canvas.h"

static NSString * const sGUIDKey   = @"GUID";
static NSString * const sXKey      = @"x";
static NSString * const sYKey      = @"y";
static NSString * const sWidthKey  = @"width";
static NSString * const sHeightKey = @"height";

@implementation CanvasObject {
    CGRect _rect;
}

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super init])) {
        NSString *GUID         = [dictionary objectForKey:sGUIDKey];
        NSNumber *xNumber      = [dictionary objectForKey:sXKey];
        NSNumber *yNumber      = [dictionary objectForKey:sYKey];
        NSNumber *widthNumber  = [dictionary objectForKey:sWidthKey];
        NSNumber *heightNumber = [dictionary objectForKey:sHeightKey];
    
        if (![GUID         isKindOfClass:[NSString class]] ||
            ![xNumber      isKindOfClass:[NSNumber class]] ||
            ![yNumber      isKindOfClass:[NSNumber class]] ||
            ![widthNumber  isKindOfClass:[NSNumber class]] ||
            ![heightNumber isKindOfClass:[NSNumber class]])
        {
            self = nil;
            return nil;
        }


        _GUID = GUID;
        _rect = CGRectMake(
            [xNumber doubleValue],
            [yNumber doubleValue],
            [widthNumber doubleValue],
            [heightNumber doubleValue]
        );
    }
    
    return self;
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
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self writeToDictionary:dictionary];
    return dictionary;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:_GUID forKey:sGUIDKey];

    [dictionary setObject:@(_rect.origin.x)    forKey:sXKey];
    [dictionary setObject:@(_rect.origin.y)    forKey:sYKey];
    [dictionary setObject:@(_rect.size.width)  forKey:sWidthKey];
    [dictionary setObject:@(_rect.size.height) forKey:sHeightKey];
}


#pragma mark - Accessors

- (void) setRect:(CGRect)rect
{
    if (!CGRectEqualToRect(_rect, rect)) {
        _rect = CGRectStandardize(rect);
        [[self canvas] objectDidUpdate:self];
    }
}


- (void) setOriginX:(CGFloat)originX
{
    CGRect rect = [self rect];
    rect.origin.x = originX;
    [self setRect:rect];
}


- (void) setOriginY:(CGFloat)originY
{
    CGRect rect = [self rect];
    rect.origin.y = originY;
    [self setRect:rect];
}


- (void) setSizeWidth:(CGFloat)sizeWidth
{
    CGRect rect = [self rect];
    rect.size.width = sizeWidth;
    [self setRect:rect];
}


- (void) setSizeHeight:(CGFloat)sizeHeight
{
    CGRect rect = [self rect];
    rect.size.height = sizeHeight;
    [self setRect:rect];
}


- (CGFloat) originX    { return _rect.origin.x;    }
- (CGFloat) originY    { return _rect.origin.y;    }
- (CGFloat) sizeWidth  { return _rect.size.width;  }
- (CGFloat) sizeHeight { return _rect.size.height; }

- (BOOL) isValid
{
    return YES;
}

@end
