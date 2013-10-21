//
//  Compatibility.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-20.
//
//

#import <Foundation/Foundation.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1090

@interface NSArray ()
- (id) firstObject;
@end

#define NSCalendarUnitEra                NSEraCalendarUnit
#define NSCalendarUnitYear               NSYearCalendarUnit
#define NSCalendarUnitMonth              NSMonthCalendarUnit
#define NSCalendarUnitDay                NSDayCalendarUnit
#define NSCalendarUnitHour               NSHourCalendarUnit
#define NSCalendarUnitMinute             NSMinuteCalendarUnit
#define NSCalendarUnitSecond             NSSecondCalendarUnit
#define NSCalendarUnitWeekday            NSWeekdayCalendarUnit
#define NSCalendarUnitWeekdayOrdinal     NSWeekdayOrdinalCalendarUnit
#define NSCalendarUnitQuarter            NSQuarterCalendarUnit
#define NSCalendarUnitWeekOfMonth        NSWeekOfMonthCalendarUnit
#define NSCalendarUnitWeekOfYear         NSWeekOfYearCalendarUnit
#define NSCalendarUnitYearForWeekOfYear  NSYearForWeekOfYearCalendarUnit
#define NSCalendarUnitCalendar           NSCalendarCalendarUnit
#define NSCalendarUnitTimeZone           NSTimeZoneCalendarUnit

@interface NSImage ()
- (void) drawInRect:(NSRect)rect;
@end

@interface NSColor ()
+ (NSColor *) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
+ (NSColor *) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (NSColor *) colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness alpha:(CGFloat)alpha;
@end

#endif

extern void InstallCompatibilityIfNeeded(void);
