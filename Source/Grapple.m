//
//  Grapple.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Grapple.h"
#import "Canvas.h"

static NSString * const sVerticalKey = @"vertical";

@implementation Grapple {
    BOOL _preview;
}

+ (instancetype) grappleVertical:(BOOL)vertical
{
    return [[self alloc] _initVertical:vertical];
}


- (id) _initVertical:(BOOL)isVertical
{
    if ((self = [super init])) {
        _vertical = isVertical;
    }
    
    return self;
}


- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super initWithDictionaryRepresentation:dictionary])) {
        NSNumber *verticalNumber = [dictionary objectForKey:sVerticalKey];

        if (!verticalNumber) {
            self = nil;
            return nil;
        }

        _vertical = [verticalNumber boolValue];
    }
    
    return self;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [super writeToDictionary:dictionary];
    [dictionary setObject:@(_vertical) forKey:sVerticalKey];
}


- (void) setPreview:(BOOL)preview
{
    @synchronized(self) {
        if (_preview != preview) {
            _preview = preview;
            [[self canvas] objectDidUpdate:self];
        }
    }
}


- (BOOL) isPreview
{
    @synchronized(self) {
        return _preview;
    }
}


- (CGFloat) length
{
    CGRect rect = [self rect];
    return _vertical ? rect.size.height : rect.size.width;
}


@end
