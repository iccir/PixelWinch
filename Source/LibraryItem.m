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
}


+ (instancetype) libraryItem
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd 'at' HH'.'mm'.'ss"];

    NSDate   *now = [NSDate date];
    NSString *directoryName = [dateFormatter stringFromDate:now];
    
    NSString *directoryToTry = [GetScreenshotsDirectory() stringByAppendingPathComponent:directoryName];
    
    NSString *actualDirectory = MakeUniqueDirectory(directoryToTry);
    
    return actualDirectory ? [[LibraryItem alloc] _initWithBasePath:actualDirectory date:now] : nil;
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
    @synchronized (self) {
        if ([self isValid]) {
            return [Screenshot screenshotWithContentsOfFile:[self screenshotPath]];
        }
    }
    
    return nil;
}


- (void) setCanvasDictionary:(NSDictionary *)canvasDictionary
{
    @synchronized (self) {
        _canvasDictionary = canvasDictionary;
        [self _writeInfo];
    }
}


- (NSDictionary *) canvasDictionary
{
    @synchronized (self) {
        return _canvasDictionary;
    }
}


- (void) setTitle:(NSString *)title
{
    @synchronized (self) {
        _title = [title copy];
        [self _writeInfo];
    }
}


- (NSString *) title
{
    @synchronized (self) {
        return _title;
    }
}


- (NSString *) titleOrDateString
{
    @synchronized (self) {
        return _title ? _title : _dateString;
    }
}


- (BOOL) isValid
{
    @synchronized (self) {
        return [[NSFileManager defaultManager] fileExistsAtPath:[self screenshotPath]];
    }
}


@end
