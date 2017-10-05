//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "ZoomTool.h"
#import "CursorAdditions.h"
#import "CanvasView.h"


static NSString * const sZoomsInKey = @"zoomsIn";


@implementation ZoomTool

- (id) init
{
    if ((self = [super init])) {
        _zoomsIn = YES;
    }
    
    return self;
}


- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super initWithDictionaryRepresentation:dictionary])) {
        NSNumber *zoomsInNumber = [dictionary objectForKey:sZoomsInKey];
        _zoomsIn = !zoomsInNumber || [zoomsInNumber boolValue];
    }
    
    return self;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:@(_zoomsIn) forKey:sZoomsInKey];
}


- (NSCursor *) cursor
{
    return [self calculatedZoomsIn] ? [NSCursor winch_zoomInCursor] : [NSCursor winch_zoomOutCursor];
}


- (NSString *) name
{
    return @"zoom";
}


- (unichar) shortcutKey
{
    return 'z';
}


- (BOOL) calculatedZoomsIn
{
    BOOL isAltPressed = ([NSEvent modifierFlags] & NSEventModifierFlagOption) > 0;

    if (_inTemporaryMode) {
        return !isAltPressed;
    }

    BOOL result = [self zoomsIn];
    if (isAltPressed) result = !result;

    return result;
}


- (void) mouseUpWithEvent:(NSEvent *)event
{
    NSInteger direction = [self calculatedZoomsIn] ? 1 : -1;
    [[self owner] zoomWithDirection:direction event:event];
}


@end
