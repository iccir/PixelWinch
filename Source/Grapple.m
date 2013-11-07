//
//  Grapple.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Grapple.h"
#import "Canvas.h"

static NSString * const sVerticalKey    = @"vertical";


@implementation Grapple {
    BOOL _preview;
}


+ (NSString *) grapples
{
    return @"grapples";
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



- (BOOL) writeToPasteboard:(NSPasteboard *)pasteboard
{
    if ([self isValid]) {
        NSString *stringToWrite = GetStringForFloat([self length]);

        [pasteboard clearContents];
        [pasteboard writeObjects:@[ stringToWrite ] ];

        return YES;

    } else {
        return NO;
    }
}


- (void) setPreview:(BOOL)preview
{
    if (_preview != preview) {
        [self beginChanges];
        _preview = preview;
        [self endChanges];
    }
}


- (CGFloat) length
{
    CGRect rect = [self rect];
    return _vertical ? rect.size.height : rect.size.width;
}


@end


