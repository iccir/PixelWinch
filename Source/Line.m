// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "Line.h"
#import "Canvas.h"

static NSString * const sVerticalKey = @"vertical";


@implementation Line {
    BOOL _preview;
}


+ (NSString *) groupName
{
    return @"lines";
}


+ (instancetype) lineVertical:(BOOL)vertical
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


- (BOOL) readFromDictionary:(NSDictionary *)dictionary
{
    if (![super readFromDictionary:dictionary]) {
        return NO;
    }

    NSNumber *verticalNumber = [dictionary objectForKey:sVerticalKey];

    if (!verticalNumber) {
        return NO;
    }

    _vertical = [verticalNumber boolValue];

    return YES;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [super writeToDictionary:dictionary];
    [dictionary setObject:@(_vertical) forKey:sVerticalKey];
}


- (NSString *) pasteboardString
{
    return GetStringForFloat([self length]);
}


- (id) duplicate
{
    if (_preview) return nil;

    Line *result = [Line lineVertical:[self isVertical]];
    [result setRect:[self rect]];
    return result;
}


- (void) setPreview:(BOOL)preview
{
    if (_preview != preview) {
        [self beginChanges];
        _preview = preview;
        [self endChanges];
    }
}


- (BOOL) isPersistent
{
    return [super isPersistent] && ![self isPreview];
}


- (CGFloat) length
{
    CGRect rect = [self rect];
    return _vertical ? rect.size.height : rect.size.width;
}


- (BOOL) isSelectable
{
    return YES;
}

@end


