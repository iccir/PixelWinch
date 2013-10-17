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

@implementation LibraryItem {
    NSString     *_basePath;
    NSDate       *_date;
    NSString     *_title;
    NSDictionary *_canvasDictionary;

    Screenshot *_screenshot;
    NSImage    *_thumbnail;
    BOOL _makingThumbnail;
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


- (id) initWithBasePath:(NSString *)basePath date:(NSDate *)date
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


- (NSString *) _thumbnailPath
{
    return [_basePath stringByAppendingPathComponent:@"thumbnail.png"];
}


- (NSString *) _infoPlistPath
{
    return [_basePath stringByAppendingPathComponent:@"info.plist"];
}


- (void) _makeThumbnail
{
    if (_makingThumbnail) return;

    if ([self isValid]) {
        _makingThumbnail = YES;

        NSURL *inURL  = [NSURL fileURLWithPath:[self screenshotPath]];
        NSURL *outURL = [NSURL fileURLWithPath:[self _thumbnailPath]];

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            CGSize maxSize = GetMaxThumbnailSize();
            
            maxSize.width  *= 2;
            maxSize.height *= 2;

            CGImageRef cgImage = QLThumbnailImageCreate(NULL, (__bridge CFURLRef)inURL, maxSize, NULL);

            CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)outURL, kUTTypePNG, 1, NULL);
            CGImageDestinationAddImage(destination, cgImage, NULL);
            
            CGImageDestinationFinalize(destination);
            
            CFRelease(destination);

            dispatch_async(dispatch_get_main_queue(), ^{
                size_t width  = CGImageGetWidth(cgImage);
                size_t height = CGImageGetHeight(cgImage);
                
                [self willChangeValueForKey:@"thumbnail"];
                _thumbnail = [[NSImage alloc] initWithCGImage:cgImage size:CGSizeMake(width / 2.0, height / 2.0f)];
                [self didChangeValueForKey:@"thumbnail"];
                
                CGImageRelease(cgImage);
            });
        });
    }
}


#pragma mark - Accessors

- (NSString *) screenshotPath
{
    return [_basePath stringByAppendingPathComponent:@"screenshot.tiff"];
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


- (NSImage *) thumbnail
{
    if (!_thumbnail) {
        NSString *thumbnailPath = [self _thumbnailPath];

        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
            _thumbnail = [[NSImage alloc] initWithContentsOfFile:thumbnailPath];

            CGSize size = [_thumbnail size];
            size.width /= 2;
            size.height /= 2;
            [_thumbnail setSize:size];
        }
        
        if (!_thumbnail) {
            [self _makeThumbnail];
        }
    }
    
    return _thumbnail;
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
