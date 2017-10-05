//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "ScreenAdditions.h"

@implementation NSScreen (PixelWinch)

static CGFloat sScreenZeroHeight()
{
    NSScreen *screenZero = [[NSScreen screens] firstObject];
    return screenZero ? [screenZero frame].size.height : 0;
}


+ (NSPoint) winch_convertPointFromGlobal:(CGPoint)globalPoint
{
    return NSMakePoint(globalPoint.x, sScreenZeroHeight() - globalPoint.y);
}


+ (CGPoint) winch_convertPointToGlobal:(NSPoint)appKitPoint
{
    return CGPointMake(appKitPoint.x, sScreenZeroHeight() - appKitPoint.y);
}


+ (NSRect) winch_convertRectFromGlobal:(CGRect)globalRect
{
    NSRect result = NSRectFromCGRect(globalRect);
    result.origin.y = sScreenZeroHeight() - CGRectGetMaxY(globalRect);
    return result;
}


+ (CGRect) winch_convertRectToGlobal:(NSRect)appKitRect
{
    CGRect result = NSRectToCGRect(appKitRect);
    result.origin.y = sScreenZeroHeight() - NSMaxY(appKitRect);
    return result;
}


static NSArray *sGetScreensWithDisplayIDs(CGDirectDisplayID *displayIDs, uint32_t count)
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    
    for (NSScreen *screen in [NSScreen screens]) {
        [map setObject:screen forKey:@( [screen winch_CGDirectDisplayID] )];
    }

    for (NSInteger i = 0; i < count; i++) {
        NSScreen *screen = [map objectForKey:@(displayIDs[i])];
        if (screen) [result addObject:screen];
    }
    
    return result;
}


+ (NSArray *) winch_screensWithGlobalPoint:(CGPoint)point
{
    uint32_t count = 0;
    CGError error = CGGetDisplaysWithPoint(point, 0, NULL, &count);
    if (error || !count) return nil;
    
    CGDirectDisplayID *displays = malloc(count * sizeof(CGDirectDisplayID));
    error = CGGetDisplaysWithPoint(point, count, displays, &count);
    
    NSArray *result = nil;
    if (!error) {
        result = sGetScreensWithDisplayIDs(displays, count);
    }
    
    free(displays);

    return result;
}


+ (NSArray *) winch_screensWithGlobalRect:(CGRect)rect
{
    uint32_t count = 0;
    CGError error = CGGetDisplaysWithRect(rect, 0, NULL, &count);
    if (error || !count) return nil;
    
    CGDirectDisplayID *displays = malloc(count * sizeof(CGDirectDisplayID));
    error = CGGetDisplaysWithRect(rect, count, displays, &count);
    
    NSArray *result = nil;
    if (!error) {
        result = sGetScreensWithDisplayIDs(displays, count);
    }
    
    free(displays);

    return result;
}


+ (instancetype) winch_screenWithGlobalRect:(CGRect)rect
{
    NSArray *screens = [self winch_screensWithGlobalRect:rect];
    
    if ([screens count] < 2) {
        return [screens lastObject];
    }

    CGFloat maxArea = -1;
    NSScreen *maxScreen = nil;
    
    for (NSScreen *screen in screens) {
        CGRect intersection = CGRectIntersection(rect, [screen winch_globalFrame]);
        CGFloat area = fabs(intersection.size.width * intersection.size.height);
        
        if (area > maxArea) {
            maxArea = area;
            maxScreen = screen;
        }
    }

    return maxScreen;
}


+ (instancetype) winch_screenWithCGDirectDisplayID:(CGDirectDisplayID)directDisplayID
{
    NSArray *results = sGetScreensWithDisplayIDs(&directDisplayID, 1);
    return [results lastObject];
}


- (CGDirectDisplayID) winch_CGDirectDisplayID
{
    NSNumber *screenNumber = [[self deviceDescription] objectForKey:@"NSScreenNumber"];
    uint32_t screenID = [screenNumber unsignedIntValue];
    return screenID;
}


- (CGRect) winch_globalFrame
{
    return CGDisplayBounds([self winch_CGDirectDisplayID]);
}


- (NSString *) winch_name
{
    NSMutableString *name = [NSMutableString string];
    NSSize screenSize = [self frame].size;
    
    if ([self backingScaleFactor] > 1) {
        [name appendFormat:@"%@ %C ", NSLocalizedString(@"Retina", nil),  (unichar)0x2013];
    }
    
    [name appendFormat:@"%g%C%g", screenSize.width, (unichar)0xD7, screenSize.height];

    NSString *spaceName = [[self colorSpace] localizedName];
    if ([spaceName length]) {
        [name appendFormat:@" %C %@", (unichar)0x2013, spaceName];
    }
    
    return name;
}

@end
