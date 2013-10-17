//
//  Screenshot.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-13.
//
//

#import "Screenshot.h"

@implementation Screenshot {
    NSString *_path;
    NSData *_fileData;
    NSBitmapImageRep *_rep;
}


+ (instancetype) screenshotWithContentsOfFile:(NSString *)path
{
    return [[self alloc] _initWithContentsOfFile:path];
}


- (id) _initWithContentsOfFile:(NSString *)path
{
    if ((self = [super init])) {
        _path = path;
        
        NSError *error;
        _fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_path] options:NSDataReadingMappedAlways error:&error];

        if (!_fileData) {
            self = nil;
            return nil;
        }
    
        NSImage *image = [[NSImage alloc] initWithData:_fileData];
        NSImageRep *largestRep = nil;

        if (!image) {
            self = nil;
            return nil;
        }

        for (NSImageRep *rep in [image representations]) {
            if (![rep isKindOfClass:[NSBitmapImageRep class]]) {
                continue;
            }

            if ([rep pixelsHigh] > _height || [rep pixelsWide] > _width) {
                _height = [rep pixelsHigh];
                _width  = [rep pixelsWide];
                largestRep = rep;
            }
        }
    
        _rep  = (NSBitmapImageRep *)largestRep;
        _size = CGSizeMake(_width, _height);

        if (!_rep) {
            self = nil;
            return nil;
        }
    }
    
    return self;
}


- (UInt8 *) RGBData
{
    if ([_rep isPlanar] || [_rep hasAlpha]) return NULL;

    NSBitmapFormat format = [_rep bitmapFormat];
    if (format & NSFloatingPointSamplesBitmapFormat) {
        return NULL;
    }

    return [_rep bitmapData];
}


- (UInt8 *) RGBAData
{
    if ([_rep isPlanar] || ![_rep hasAlpha]) return NULL;

    // Ensure we aren't float, or ARGB
    //
    NSBitmapFormat format = [_rep bitmapFormat];
    if ((format & NSFloatingPointSamplesBitmapFormat) ||
        (format & NSAlphaFirstBitmapFormat))
    {
        return NULL;
    }

    return [_rep bitmapData];
}

- (NSInteger) bytesPerRow
{
    return [_rep bytesPerRow];
}


- (CGImageRef) CGImage
{
    return [_rep CGImage];
}


@end
