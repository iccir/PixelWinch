//
//  GrappleTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "GrappleTool.h"
#import "CursorAdditions.h"

static NSString * const sVerticalKey  = @"vertical";
static NSString * const sToleranceKey = @"tolerance";

@implementation GrappleTool

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super initWithDictionaryRepresentation:dictionary])) {
        NSNumber *verticalNumber  = [dictionary objectForKey:sVerticalKey];
        NSNumber *toleranceNumber = [dictionary objectForKey:sToleranceKey];

        _vertical  = !verticalNumber  || [verticalNumber  boolValue];
        _tolerance = [toleranceNumber integerValue];
    }
    
    return self;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:@(_vertical)  forKey:sVerticalKey];
    [dictionary setObject:@(_tolerance) forKey:sToleranceKey];
}



- (ToolType) type { return ToolTypeGrapple; }



- (NSCursor *) cursor
{
    return [self calculatedIsVertical] ? [NSCursor winch_grappleVerticalCursor] : [NSCursor winch_grappleHorizontalCursor];
}


- (BOOL) calculatedIsVertical
{
    BOOL isAltPressed = ([NSEvent modifierFlags] & NSAlternateKeyMask) > 0;

    BOOL result = [self isVertical];
    if (isAltPressed) result = !result;

    return result;
}


- (UInt8) calculatedThreshold
{
    UInt8 threshold = ([self tolerance] / 100.0) * 255.0;
    return threshold;
}


@end
