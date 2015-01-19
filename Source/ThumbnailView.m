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


static CGSize sGetThumbnailSizeForScreenshotImage(CGImageRef screenshotImage)
{
    CGSize toSize = GetMaxThumbnailSize();
    toSize.width  *= 2;
    toSize.height *= 2;

    CGSize scaledSize;
    
    CGFloat aspect = (CGFloat)CGImageGetWidth(screenshotImage) / CGImageGetHeight(screenshotImage);
    if ((toSize.width / aspect) < toSize.height) {
        scaledSize = CGSizeMake(toSize.width, toSize.width / aspect);
    } else {
        scaledSize = CGSizeMake(toSize.height * aspect, toSize.height);
    }
    
    scaledSize.width  = round(scaledSize.width  / 2) * 2;
    scaledSize.height = round(scaledSize.height / 2) * 2;

    return scaledSize;
}


@implementation ThumbnailView {
    LibraryItem *_libraryItem;
    NSImage     *_thumbnailImage;

    XUIView     *_borderView;
    XUIView     *_imageView;
    NSButton    *_deleteButton;

    BOOL _selected;
    BOOL _makingThumbnail;
}


- (id) initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        _imageView  = [[XUIView alloc] initWithFrame:CGRectZero];
        _borderView = [[XUIView alloc] initWithFrame:CGRectZero];
        
        _deleteButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 17, 17)];
        [_deleteButton setImage:[NSImage imageNamed:@"DeleteNormal"]];
        [_deleteButton setAlternateImage:[NSImage imageNamed:@"DeletePressed"]];
        [_deleteButton setBordered:NO];
        [_deleteButton setButtonType:NSMomentaryLightButton];
        [_deleteButton setTarget:self];
        [_deleteButton setAction:@selector(_handleDeleteButton:)];

        [_borderView setBackgroundColor:[NSColor whiteColor]];
        
        [self addSubview:_borderView];
        [self addSubview:_imageView];
        [self addSubview:_deleteButton];
        
        [self _updateSelection];
    }
    
    return self;
}


- (void) dealloc
{
    [_libraryItem removeObserver:self forKeyPath:@"thumbnail"];
    _libraryItem = nil;
}


- (void) loadThumbnail
{
    __weak id weakSelf = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ThumbnailView *view = weakSelf;
        if (!view) return;
        
        LibraryItem *item = [view libraryItem];
    
        NSString *thumbnailPath = [item thumbnailPath];
        NSImage  *thumbnail = nil;
    
        // Thumbnails are always made as 2x images
    
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
            thumbnail = [[NSImage alloc] initWithContentsOfFile:thumbnailPath];

            CGSize size = [thumbnail size];
            size.width  /= 2;
            size.height /= 2;
            [thumbnail setSize:size];
        }
        
        if (!thumbnail && [item isValid]) {
            CGImageRef screenshotImage = CGImageRetain([[item screenshot] CGImage]);
            CGSize thumbnailSize = sGetThumbnailSizeForScreenshotImage(screenshotImage);

            NSURL *outURL = [NSURL fileURLWithPath:[item thumbnailPath]];

            size_t bitsPerComponent = CGImageGetBitsPerComponent(screenshotImage);

            CGImageRef outImage = NULL;

            CGColorSpaceRef colorSpace = CGImageGetColorSpace(screenshotImage);
            size_t numberOfComponents = (CGColorSpaceGetNumberOfComponents(colorSpace) + 1);

            CGContextRef context = CGBitmapContextCreate(NULL, thumbnailSize.width, thumbnailSize.height, bitsPerComponent, thumbnailSize.width * numberOfComponents, colorSpace, 0|kCGImageAlphaNoneSkipLast);

            CGContextDrawImage(context, CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height), screenshotImage);

            outImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);

            if (outImage) {
                CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)outURL, kUTTypePNG, 1, NULL);
                CGImageDestinationAddImage(destination, outImage, NULL);
                
                CGImageDestinationFinalize(destination);
                
                CFRelease(destination);

                size_t width  = CGImageGetWidth(outImage);
                size_t height = CGImageGetHeight(outImage);
                
                thumbnail = [[NSImage alloc] initWithCGImage:outImage size:CGSizeMake(width / 2.0, height / 2.0f)];

                CGImageRelease(outImage);
            }
        }
        
        if (thumbnail) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf _setThumbnailImage:thumbnail];
            });
        }
    });
}


- (void) _setThumbnailImage:(NSImage *)image
{
    _thumbnailImage = image;

    [[_imageView layer] setContentsGravity:kCAGravityResize];
    [[_imageView layer] setContents:image];

    [self setNeedsLayout];
}


- (void) _handleDeleteButton:(id)sender
{
    [_delegate thumbnailViewDidClickDelete:self];
}


- (void) layout
{
    [super layout];
    
    if (!_thumbnailImage) return;

    CGRect bounds = [self bounds];

    CGSize size = [_thumbnailImage size];
    
    CGRect imageFrame = CGRectMake(
        round((bounds.size.width  - size.width)  / 2),
        round((bounds.size.height - size.height) / 2),
        size.width,
        size.height
    );

    [_imageView setFrame:imageFrame];
    [_borderView setFrame:CGRectInset(imageFrame, -2, -2)];


    CGRect deleteFrame = [_deleteButton frame];
    
    CGFloat maxY = bounds.size.height - deleteFrame.size.height;
    
    CGPoint origin = CGPointMake(imageFrame.origin.x, bounds.size.height - (imageFrame.origin.y + deleteFrame.size.height));
    deleteFrame.origin = origin;
    deleteFrame.origin.x -= 9;
    deleteFrame.origin.y += 9;
    
    if (deleteFrame.origin.x < 0)    deleteFrame.origin.x = 0;
    if (deleteFrame.origin.y > maxY) deleteFrame.origin.y = maxY;

    [_deleteButton setFrame:deleteFrame];
}


- (void) _updateSelection
{
    if ([self isSelected]) {
        [_borderView setBackgroundColor:GetRGBColor(0x0D72FE, 1.0)];
        [_deleteButton setHidden:NO];
        [_deleteButton setEnabled:YES];
    } else {
        [_borderView setBackgroundColor:[NSColor whiteColor]];
        [_deleteButton setHidden:YES];
        [_deleteButton setEnabled:NO];
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _libraryItem) {
        if ([keyPath isEqualToString:@"thumbnail"]) {
            _thumbnailImage = nil;
            [self loadThumbnail];
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
            [self _updateSelection];
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
