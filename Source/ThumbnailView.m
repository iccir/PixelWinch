//
//  ThumbnailView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import "ThumbnailView.h"
#import "LibraryItem.h"
#import "Screenshot.h"



@implementation ThumbnailView {
    LibraryItem *_libraryItem;
    NSImage     *_thumbnail;
    BOOL _selected;
    BOOL _makingThumbnail;
}


+ (CGSize) thumbnailSizeForLibraryItem:(LibraryItem *)libraryItem
{
    CGImageRef screenshot = [[libraryItem screenshot] CGImage];

    CGSize toSize = GetMaxThumbnailSize();
    toSize.width  *= 2;
    toSize.height *= 2;

    CGSize scaledSize;
    
    CGFloat aspect = (CGFloat)CGImageGetWidth(screenshot) / CGImageGetHeight(screenshot);
    if ((toSize.width / aspect) < toSize.height) {
        scaledSize = CGSizeMake(toSize.width, toSize.width / aspect);
    } else {
        scaledSize = CGSizeMake(toSize.height * aspect, toSize.height);
    }
    
    scaledSize.width  = round(scaledSize.width  / 2);
    scaledSize.height = round(scaledSize.height / 2);

    return scaledSize;
}


- (void) dealloc
{
    [_libraryItem removeObserver:self forKeyPath:@"thumbnail"];
    _libraryItem = nil;
}


- (void) _makeThumbnail
{
    if (_makingThumbnail) return;

    __weak id weakSelf = self;

    if ([_libraryItem isValid]) {
        _makingThumbnail = YES;

        CGSize thumbnailSize = [ThumbnailView thumbnailSizeForLibraryItem:_libraryItem];
        thumbnailSize.width  *= 2;
        thumbnailSize.height *= 2;

        CGImageRef inImage = CGImageRetain([[_libraryItem screenshot] CGImage]);
        NSURL *outURL = [NSURL fileURLWithPath:[_libraryItem thumbnailPath]];

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            size_t bitsPerComponent = CGImageGetBitsPerComponent(inImage);

            CGImageRef outImage = NULL;

            CGColorSpaceRef colorSpace = CGImageGetColorSpace(inImage);
            size_t numberOfComponents = (CGColorSpaceGetNumberOfComponents(colorSpace) + 1);

            CGContextRef context = CGBitmapContextCreate(NULL, thumbnailSize.width, thumbnailSize.height, bitsPerComponent, thumbnailSize.width * numberOfComponents, colorSpace, 0|kCGImageAlphaNoneSkipLast);

            CGContextDrawImage(context, CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height), inImage);

            outImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);

            if (outImage) {
                CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)outURL, kUTTypePNG, 1, NULL);
                CGImageDestinationAddImage(destination, outImage, NULL);
                
                CGImageDestinationFinalize(destination);
                
                CFRelease(destination);

                dispatch_async(dispatch_get_main_queue(), ^{
                    size_t width  = CGImageGetWidth(outImage);
                    size_t height = CGImageGetHeight(outImage);
                    
                    NSImage *image = [[NSImage alloc] initWithCGImage:outImage size:CGSizeMake(width / 2.0, height / 2.0f)];
                    [weakSelf _updateThumbnail:image];

                    CGImageRelease(outImage);
                });
            }
        });
    }
}


- (void) _updateThumbnail:(NSImage *)thumbnail
{
    _thumbnail = thumbnail;
    _makingThumbnail = NO;

    [self setNeedsDisplay:YES];
}


- (NSImage *) _thumbnail
{
    if (_makingThumbnail) return nil;

    if (!_thumbnail) {
        NSString *thumbnailPath = [_libraryItem thumbnailPath];

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


- (CGRect) _thumbnailRect
{
    CGSize size   = [ThumbnailView thumbnailSizeForLibraryItem:_libraryItem];
    CGRect bounds = [self bounds];

    return CGRectMake(
        round((bounds.size.width  - size.width)  / 2),
        round((bounds.size.height - size.height) / 2),
        size.width,
        size.height
    );
}


- (CGPoint) topLeftOffset
{
    return [self _thumbnailRect].origin;
}


- (void) drawRect:(NSRect)dirtyRect
{
    NSImage *thumbnail = [self _thumbnail];

    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGRect thumbnailRect = [self _thumbnailRect];

    // Draw thumbnail
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowColor:GetRGBColor(0x0, 1.0)];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:2];

        [shadow set];

        if (thumbnail) {
            CGSize fromSize = [thumbnail size];
            CGRect fromRect = CGRectMake(0, 0, fromSize.width, fromSize.height);

            [thumbnail drawInRect:thumbnailRect fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];

        } else {
            CGImageRef screenshot = [[_libraryItem screenshot] CGImage];
        
            CGContextSaveGState(context);
            CGContextDrawImage(context, [self _thumbnailRect], screenshot);

            CGContextRestoreGState(context);
        }
    }

    NSBezierPath *outerPath = [NSBezierPath bezierPathWithRect:thumbnailRect];
    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRect:CGRectInset(thumbnailRect, 2, 2)];
    
    [outerPath appendBezierPath:[innerPath bezierPathByReversingPath]];

    NSShadow *shadow = [[NSShadow alloc] init];
    
    if ([self isSelected]) {
        [shadow setShadowColor:GetRGBColor(0x0, 1.0)];
    } else {
        [shadow setShadowColor:GetRGBColor(0x0, 0.75)];
    }
 
    [shadow setShadowOffset:NSMakeSize(0, 0)];
    [shadow setShadowBlurRadius:1];

    [shadow set];

    if ([self isSelected]) {
        [GetRGBColor(0x0D72FE, 1.0) set];
    } else {
        [[NSColor whiteColor] set];
    }
    
    [outerPath fill];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _libraryItem) {
        if ([keyPath isEqualToString:@"thumbnail"]) {
            [self setNeedsDisplay:YES];
        }
    }
}


- (void) setLibraryItem:(LibraryItem *)libraryItem
{
    @synchronized(self) {
        if (_libraryItem != libraryItem) {
            [_libraryItem removeObserver:self forKeyPath:@"thumbnail"];
            _libraryItem = libraryItem;
            [_libraryItem addObserver:self forKeyPath:@"thumbnail" options:0 context:NULL];
        }
    }
}


- (LibraryItem *) libraryItem
{
    @synchronized(self) {
        return _libraryItem;
    }
}


- (void) setSelected:(BOOL)selected
{
    @synchronized(self) {
        if (_selected != selected) {
            _selected = selected;
            [self setNeedsDisplay:YES];
        }
    }
}


- (BOOL) isSelected
{
    @synchronized(self) {
        return _selected;
    }
}

@end
