//
//  Library.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-08.
//
//

#import "Library.h"
#import "LibraryItem.h"

@interface LibraryItem ()
- (id) _initWithBasePath:(NSString *)basePath date:(NSDate *)date;
- (NSString *) _basePath;
@end


@interface Library ()
@property (strong) NSMutableArray *items;
@end


@implementation Library {
    NSMutableArray *_items;
}


+ (id) sharedInstance
{
    static Library *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[Library alloc] init];
    });
    
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        [self _populateItems];
    }

    return self;
}


- (void) _populateItems
{
    NSMutableArray *items = [NSMutableArray array];

    NSString *screenshotsPath = GetScreenshotsDirectory();
    NSFileManager *manager = [NSFileManager defaultManager];

    if ([manager fileExistsAtPath:screenshotsPath]) {
        NSError *error = nil;
        for (NSString *pathComponent in [manager contentsOfDirectoryAtPath:screenshotsPath error:&error]) {
        
            NSString *basePath = [screenshotsPath stringByAppendingPathComponent:pathComponent];
            
            LibraryItem *item = [[LibraryItem alloc] _initWithBasePath:basePath date:nil];
            if ([item isValid]) {
                [items addObject:item];
            }
        }

        if (error) {
            WinchWarn(@"Library", @"_populateItems error: %@", error);
        }
    }
    
    [self setItems:items];
    
    [self _calculateFriendlyNamesForItems:items];
}


- (void) _calculateFriendlyNamesForItems:(NSArray *)items
{
    NSDateFormatter *shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
    [shortDateFormatter setDoesRelativeDateFormatting:YES];

    NSDateFormatter *dayNameFormatter = [[NSDateFormatter alloc] init];
    [dayNameFormatter setDateFormat:@"EEEE"];
   
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];

    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate    *today          = [NSDate date];
    NSUInteger todayDayOfYear = [gregorianCalendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSYearCalendarUnit forDate:today];
    NSDateComponents *todayComponents = [gregorianCalendar components:(NSCalendarUnitYear | NSCalendarUnitWeekday) fromDate:today];

    for (LibraryItem *item in items) {
        NSDate *date = [item date];
        if (!date) continue;

        NSUInteger        dateDayOfYear  = [gregorianCalendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSYearCalendarUnit forDate:date];
        NSDateComponents *dateComponents = [gregorianCalendar components:(NSCalendarUnitYear | NSCalendarUnitWeekday) fromDate:date];

        id dateString = [shortDateFormatter stringFromDate:date];
        NSString *timeString  = [timeFormatter stringFromDate:date];

        // Same year
        if ([dateComponents year] == [todayComponents year]) {
            // Today
            if (todayDayOfYear == dateDayOfYear) {
                dateString = nil;

            // Yesterday
            } else if (dateDayOfYear == (todayDayOfYear - 1)) {
                // shortDateFormatter takes care of this

            // Within past week
            } else if (dateDayOfYear > (todayDayOfYear - 5)) {
                dateString = [dayNameFormatter stringFromDate:date];
            }
        }

        if (dateString) {
            [item setDateString:[NSString stringWithFormat:@"%@, %@", dateString, timeString]];
        } else {
            [item setDateString:timeString];
        }
    }
}


- (void) addItem:(LibraryItem *)item
{
    if (item) {
        [self _calculateFriendlyNamesForItems:@[ item ]];
        [[self mutableArrayValueForKey:@"items"] addObject:item];
    }
}


- (void) removeItem:(LibraryItem *)item
{
    [[self mutableArrayValueForKey:@"items"] removeObject:item];
    [self discardItem:item];
}


- (void) discardItem:(LibraryItem *)item
{
    NSString *basePath = [item _basePath];
    
    if (basePath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:basePath error:&error];
    }

    if ([_items containsObject:item]) {
        [_items removeObject:item];
    }
}


#pragma mark - KVC Compliance

- (void) insertItems:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [_items insertObjects:array atIndexes:indexes];
}


- (void) removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [_items removeObjectsAtIndexes:indexes];
}


@end

