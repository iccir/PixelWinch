//
//  Screenshot.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-13.
//
//

#import <ImageIO/ImageIO.h>

#import "Screenshot.h"

static NSCache    *sScreenshotCache    = nil;
static Screenshot *sLastScreenshot     = nil;
static NSString   *sLastScreenshotPath = nil;

@implementation Screenshot


+ (instancetype) screenshotWithContentsOfFile:(NSString *)path
{
    if (!sScreenshotCache) {
        sScreenshotCache = [[NSCache alloc] init];
        [sScreenshotCache setCountLimit:3];
    }

    Screenshot *screenshot = [sScreenshotCache objectForKey:path];

    if (!screenshot && [sLastScreenshotPath isEqualToString:path]) {
        return sLastScreenshot;
    }

    if (!screenshot) {
        screenshot = [[self alloc] _initWithContentsOfFile:path];

        if (screenshot) {
            [sScreenshotCache setObject:screenshot forKey:path];
        }

        sLastScreenshotPath = path;
        sLastScreenshot = screenshot;
    }
    
    return screenshot;
}


+ (void) clearCache
{
    [sScreenshotCache removeAllObjects];

    sLastScreenshot     = nil;
    sLastScreenshotPath = nil;
}


- (id) _initWithContentsOfFile:(NSString *)path
{
    if ((self = [super init])) {
        [self _readFileAtPath:path];

        if (!_CGImage) {
            self = nil;
            return nil;
        }
    }
    
    return self;
}


- (void) dealloc
{
    CGImageRelease(_CGImage);
    _CGImage = NULL;
}


- (void) _readFileAtPath:(NSString *)path
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
    if (!imageSource) return;
    
    NSInteger indexOfLargestImage = NSNotFound;
    
    size_t count = CGImageSourceGetCount(imageSource);
    for (NSInteger i = 0; i < count; i++) {
        NSDictionary *properties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, i, NULL));

        size_t width  = [[properties objectForKey:(__bridge id)kCGImagePropertyPixelWidth]  unsignedLongValue];
        size_t height = [[properties objectForKey:(__bridge id)kCGImagePropertyPixelHeight] unsignedLongValue];
        
        if ((height > _height) || (width > _width)) {
            _height = height;
            _width  = width;
            indexOfLargestImage = i;
        }
    }
    
    if (indexOfLargestImage != NSNotFound) {
        _CGImage = CGImageSourceCreateImageAtIndex(imageSource, indexOfLargestImage, NULL);
        _size    = CGSizeMake(_width, _height);
    }
    
    CFRelease(imageSource);
}


- (BOOL) isOpaque
{
    if (_CGImage) {
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(_CGImage);
        
        return alphaInfo == kCGImageAlphaNone ||
               alphaInfo == kCGImageAlphaNoneSkipFirst ||
               alphaInfo == kCGImageAlphaNoneSkipLast;
    }

    return YES;
}

@end
