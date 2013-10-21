//
//  LibraryItem.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import "LibraryItem.h"
#import "Screenshot.h"

#import <QuickLook/QuickLook.h>

static NSString * const sTitleKey  = @"title";
static NSString * const sDateKey   = @"date";
static NSString * const sCanvasKey = @"canvas";

@interface LibraryItem ()
@property (nonatomic, strong) NSImage *thumbnail;
@end

@implementation LibraryItem {
    NSString     *_basePath;
    NSDate       *_date;
    NSString     *_title;
    NSDictionary *_canvasDictionary;

    Screenshot *_screenshot;
}


+ (instancetype) libraryItem
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];

    NSDateFormatter *shortTimeFormatter = [[NSDateFormatter alloc] init];

    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterMediumStyle];

    [shortTimeFormatter setDateStyle:NSDateFormatterNoStyle];
    [shortTimeFormatter setTimeStyle:NSDateFormatterShortStyle];

    NSDate   *now = [NSDate date];
    NSString *dateString = [dateFormatter stringFromDate:now];
    NSString *timeString = [timeFormatter stringFromDate:now];
    
    NSString *directoryName = [NSString stringWithFormat:@"%@ at %@", dateString, timeString];
    directoryName = [directoryName stringByReplacingOccurrencesOfString:@":" withString:@"."];

    NSString *directoryToTry = [GetScreenshotsDirectory() stringByAppendingPathComponent:directoryName];
    
    NSString *actualDirectory = MakeUniqueDirectory(directoryToTry);
    
    LibraryItem *item = [[LibraryItem alloc] _initWithBasePath:actualDirectory date:now];

    [item setDateString:[shortTimeFormatter stringFromDate:now]];
    
    return item;
}


+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;
 
    if ([key isEqualToString:@"titleOrDateString"]) {
        affectingKeys = @[ @"title", @"dateString" ];
    }
 
    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
 
    return keyPaths;
}


- (id) _initWithBasePath:(NSString *)basePath date:(NSDate *)date
{
    if ((self = [super init])) {
        _basePath = basePath;
        _date = date;

        [self _readInfo];
        if (date && ![[NSFileManager defaultManager] fileExistsAtPath:[self _infoPlistPath]]) {
            [self _writeInfo];
        }
    }

    return self;
}


#pragma mark - Private Methods

- (void) _writeInfo
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (_title)            [dictionary setObject:_title forKey:sTitleKey];
    if (_date)             [dictionary setObject:_date  forKey:sDateKey];
    if (_canvasDictionary) [dictionary setObject:_canvasDictionary forKey:sCanvasKey];

    [dictionary writeToFile:[self _infoPlistPath] atomically:YES];
}


- (void) _readInfo
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[self _infoPlistPath]];
    
    NSString     *title  = [dictionary objectForKey:sTitleKey];
    NSDate       *date   = [dictionary objectForKey:sDateKey];
    NSDictionary *canvas = [dictionary objectForKey:sCanvasKey];

    if ([title isKindOfClass:[NSString class]]) {
        _title = title;
    }
    
    if ([date isKindOfClass:[NSDate class]]) {
        _date = date;
    }

    if ([canvas isKindOfClass:[NSDictionary class]]) {
        _canvasDictionary = canvas;
    }
}


- (NSString *) _basePath
{
    return _basePath;
}


- (NSString *) _infoPlistPath
{
    return [_basePath stringByAppendingPathComponent:@"info.plist"];
}


#pragma mark - Accessors

- (NSString *) screenshotPath
{
    return [_basePath stringByAppendingPathComponent:@"screenshot.tiff"];
}


- (NSString *) thumbnailPath
{
    return [_basePath stringByAppendingPathComponent:@"thumbnail.png"];
}


- (Screenshot *) screenshot
{
    if (!_screenshot) {
        if ([self isValid]) {
            _screenshot = [Screenshot screenshotWithContentsOfFile:[self screenshotPath]];
        }
    }
    
    return _screenshot;
}


- (void) setCanvasDictionary:(NSDictionary *)canvasDictionary
{
    if (_canvasDictionary != canvasDictionary) {
        _canvasDictionary = canvasDictionary;
        [self _writeInfo];
    }
}


- (void) setTitle:(NSString *)title
{
    if (_title != title) {
        _title = title;
        [self _writeInfo];
    }
}


- (NSString *) titleOrDateString
{
    return _title ?: _dateString;
}


- (BOOL) isValid
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self screenshotPath]];
}


@end
