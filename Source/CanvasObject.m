//
//  CanvasObject.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "CanvasObject.h"
#import "Canvas.h"

static NSString * const sGUIDKey      = @"GUID";
static NSString * const sTimestampKey = @"t";
static NSString * const sXKey         = @"x";
static NSString * const sYKey         = @"y";
static NSString * const sWidthKey     = @"width";
static NSString * const sHeightKey    = @"height";

static NSString * const sGroupNameKey = @"groupName";

NSString * const PasteboardTypeCanvasObjects = @"com.pixelwinch.PixelWinch.PasteboardTypeCanvasObjects";

static NSMutableDictionary *sGroupNameToClassMap = nil;

@implementation CanvasObject {
    CGRect    _rect;
    CGPoint   _relativeMoveOrigin;
    NSInteger _changeCount;
}


+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;
 
    if ([key isEqualToString:@"originX"]) {
        affectingKeys = @[ @"rect" ];
    } else if ([key isEqualToString:@"originY"]) {
        affectingKeys = @[ @"rect" ];
    } else if ([key isEqualToString:@"sizeWidth"]) {
        affectingKeys = @[ @"rect" ];
    } else if ([key isEqualToString:@"sizeHeight"]) {
        affectingKeys = @[ @"rect" ];
    }

    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
 
    return keyPaths;
}



+ (void) initialize
{
    if (!sGroupNameToClassMap) {
        sGroupNameToClassMap = [NSMutableDictionary dictionary];
    }

    [sGroupNameToClassMap setObject:self forKey:[self groupName]];
}


+ (NSData *) pasteboardDataWithCanvasObjects:(NSArray<CanvasObject *> *)objects
{
    if (!objects) return nil;

    NSMutableArray *dictionaries = [NSMutableArray array];
    
    for (CanvasObject *object in objects) {
        NSMutableDictionary *dictionary = [[object dictionaryRepresentation] mutableCopy];
        [dictionary setObject:[[object class] groupName] forKey:sGroupNameKey];
        if (dictionary) [dictionaries addObject:dictionary];
    }

    NSError *error = nil;
    NSData  *data  = [NSPropertyListSerialization dataWithPropertyList:dictionaries format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    
    return (data && !error) ? data : nil;
}


+ (NSArray<CanvasObject *> *) canvasObjectsWithPasteboardData:(NSData *)data
{
    if (!data) return nil;

    NSMutableArray *result = [NSMutableArray array];
    NSArray *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:nil];

    if ([plist isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dictionary in plist) {
            NSString *groupName = [dictionary objectForKey:sGroupNameKey];
            if (!groupName) continue;

            Class cls = [sGroupNameToClassMap objectForKey:groupName];
            if (!cls) continue;

            CanvasObject *object = [[cls alloc] init];
            if (!object) continue;

            NSString      *GUID      = [object GUID];
            NSTimeInterval timestamp = [object timestamp];
            
            [object readFromDictionary:dictionary];
            
            object->_GUID      = GUID;
            object->_timestamp = timestamp;
                        
            [result addObject:object];
        }
    }
    
    return result;
}


+ (CanvasObject *) canvasObjectWithGroupName:(NSString *)groupName dictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
    Class cls = [sGroupNameToClassMap objectForKey:groupName];
    return [[cls alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
}


+ (NSString *) groupName
{
    return @"objects";
}


- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [self init])) {
        if (![self readFromDictionary:dictionary]) {
            self = nil;
            return nil;
        }
    }
    
    return self;
}


- (id) init
{
    if ((self = [super init])) {
        _GUID = [NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), [[NSUUID UUID] UUIDString]];
        _timestamp = [NSDate timeIntervalSinceReferenceDate];
        [self setParticipatesInUndo:YES];
        [self setPersistent:YES];
    }

    return self;
}



- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self writeToDictionary:dictionary];
    return dictionary;
}


- (NSArray<NSString *> *) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return @[ ];
}


- (nullable id) pasteboardPropertyListForType:(NSString *)type
{
    return nil;
}


- (void) beginChanges
{
    if (_changeCount == 0) {
        [[self canvas] canvasObjectWillUpdate:self];
    }

    _changeCount++;
}


- (void) endChanges
{
    _changeCount--;

    if (_changeCount == 0) {
        [[self canvas] canvasObjectDidUpdate:self];
    }
}


- (void) prepareRelativeMove
{
    _relativeMoveOrigin = [self rect].origin;
}


- (void) performRelativeMoveWithDeltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY
{
    CGRect rect = [self rect];

    rect.origin.x = _relativeMoveOrigin.x + deltaX;
    rect.origin.y = _relativeMoveOrigin.y + deltaY;

    [self setRect:rect];
}


- (BOOL) readFromDictionary:(NSDictionary *)dictionary
{
    NSString *GUID            = [dictionary objectForKey:sGUIDKey];
    NSNumber *xNumber         = [dictionary objectForKey:sXKey];
    NSNumber *yNumber         = [dictionary objectForKey:sYKey];
    NSNumber *widthNumber     = [dictionary objectForKey:sWidthKey];
    NSNumber *heightNumber    = [dictionary objectForKey:sHeightKey];
    NSNumber *timestampNumber = [dictionary objectForKey:sTimestampKey];

    if (![GUID         isKindOfClass:[NSString class]] ||
        ![xNumber      isKindOfClass:[NSNumber class]] ||
        ![yNumber      isKindOfClass:[NSNumber class]] ||
        ![widthNumber  isKindOfClass:[NSNumber class]] ||
        ![heightNumber isKindOfClass:[NSNumber class]])
    {
        return NO;
    }


    _GUID = GUID;
    _timestamp = [timestampNumber doubleValue];
    _rect = CGRectMake(
        [xNumber doubleValue],
        [yNumber doubleValue],
        [widthNumber doubleValue],
        [heightNumber doubleValue]
    );
    
    return YES;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:_GUID         forKey:sGUIDKey];
    [dictionary setObject:@(_timestamp) forKey:sTimestampKey];

    [dictionary setObject:@(_rect.origin.x)    forKey:sXKey];
    [dictionary setObject:@(_rect.origin.y)    forKey:sYKey];
    [dictionary setObject:@(_rect.size.width)  forKey:sWidthKey];
    [dictionary setObject:@(_rect.size.height) forKey:sHeightKey];
}


#pragma mark - Accessors

- (void) setRect:(CGRect)rect
{
    if (!CGRectEqualToRect(_rect, rect)) {
        [self beginChanges];
        _rect = CGRectStandardize(rect);
        [self endChanges];
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


- (NSString *) pasteboardString
{
    return nil;
}


- (BOOL) isValid
{
    return YES;
}


- (BOOL) isSelectable
{
    return NO;
}


- (id) duplicate
{
    return nil;
}


@end
