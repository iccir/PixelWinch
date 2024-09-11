// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "ThumbnailView.h"
#import "LibraryItem.h"
#import "Screenshot.h"
#import "BaseView.h"


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

    if (!scaledSize.width)  scaledSize.width = 1;
    if (!scaledSize.height) scaledSize.height = 1;
    
    return scaledSize;
}


@implementation ThumbnailView {
    LibraryItem *_libraryItem;
    NSImage     *_thumbnailImage;

    BaseView    *_borderView;
    BaseView    *_imageView;
    NSButton    *_deleteButton;

    BOOL _selected;
    BOOL _makingThumbnail;
}


#pragma mark - Superclass Overrides

- (id) initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        _deleteButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 17, 17)];
        [_deleteButton setImage:[NSImage imageNamed:@"DeleteNormal"]];
        [_deleteButton setAlternateImage:[NSImage imageNamed:@"DeletePressed"]];
        [_deleteButton setBordered:NO];
        [_deleteButton setButtonType:NSButtonTypeMomentaryChange];
        [_deleteButton setTarget:self];
        [_deleteButton setAction:@selector(_handleDeleteButton:)];

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


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _libraryItem) {
        if ([keyPath isEqualToString:@"thumbnail"]) {
            _thumbnailImage = nil;
            [self loadThumbnail];
        }
    }
}


- (void) layout
{
    CGRect bounds = [self bounds];
    CGRect deleteFrame = [_deleteButton frame];
    
    CGRect imageFrame = [self _imageFrame];
    CGFloat maxY = bounds.size.height - deleteFrame.size.height;
    
    CGPoint origin = CGPointMake(imageFrame.origin.x, bounds.size.height - (imageFrame.origin.y + deleteFrame.size.height));
    deleteFrame.origin = origin;
    deleteFrame.origin.x -= 9;
    deleteFrame.origin.y += 9;
    
    if (deleteFrame.origin.x < 0)    deleteFrame.origin.x = 0;
    if (deleteFrame.origin.y > maxY) deleteFrame.origin.y = maxY;

    [_deleteButton setFrame:deleteFrame];
}


- (void) drawRect:(NSRect)dirtyRect
{
    if (!_thumbnailImage) return;

    if ([self isSelected]) {
        [[NSColor selectedContentBackgroundColor] set];
    } else {
        [[NSColor textColor] set];
    }

    NSRect imageFrame = [self _imageFrame];
    [[NSBezierPath bezierPathWithRect:CGRectInset(imageFrame, -2, -2)] fill];
    [_thumbnailImage drawInRect:imageFrame];
}



#pragma mark - Private Methods

- (void) _updateSelection
{
    if ([self isSelected]) {
        [_deleteButton setHidden:NO];
        [_deleteButton setEnabled:YES];
    } else {
        [_deleteButton setHidden:YES];
        [_deleteButton setEnabled:NO];
    }
}


- (void) _updateThumbnailImage:(NSImage *)image
{
    if (image != _thumbnailImage) {
        _thumbnailImage = image;
        [self setNeedsLayout:YES];
        [self setNeedsDisplay:YES];
    }
}


- (void) _handleDeleteButton:(id)sender
{
    [_delegate thumbnailViewDidClickDelete:self];
}


- (CGRect) _imageFrame
{
    CGRect bounds = [self bounds];

    CGSize size = [_thumbnailImage size];
    
    CGRect imageFrame = CGRectMake(
        round((bounds.size.width  - size.width)  / 2),
        round((bounds.size.height - size.height) / 2),
        size.width,
        size.height
    );

    return imageFrame;
}






#pragma mark - Public Methods

- (void) loadThumbnail
{
    __weak id weakSelf = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ThumbnailView *strongSelf = weakSelf;
        if (!strongSelf) return;
        
        LibraryItem *item = [strongSelf libraryItem];
    
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
            if (!screenshotImage) return;
            
            CGSize thumbnailSize = sGetThumbnailSizeForScreenshotImage(screenshotImage);

            NSURL *outURL = [NSURL fileURLWithPath:[item thumbnailPath]];

            CGImageRef outImage = NULL;

            CGColorSpaceRef colorSpace = CGImageGetColorSpace(screenshotImage);
        
            if (CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB) {
                colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
            } else {
                if (colorSpace) CFRetain(colorSpace);
            }

            size_t numberOfComponents = (CGColorSpaceGetNumberOfComponents(colorSpace) + 1);

            CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(screenshotImage);

            if (alphaInfo == kCGImageAlphaLast) {
                alphaInfo = kCGImageAlphaPremultipliedLast;
            } else if (alphaInfo == kCGImageAlphaFirst) {
                alphaInfo = kCGImageAlphaPremultipliedFirst;
            } else if (alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst) {
                alphaInfo = kCGImageAlphaNoneSkipLast;
            }

            CGBitmapInfo bitmapInfo = 0 | alphaInfo;
            CGContextRef context = CGBitmapContextCreate(NULL, thumbnailSize.width, thumbnailSize.height, 8, thumbnailSize.width * numberOfComponents, colorSpace, bitmapInfo);

            CGContextDrawImage(context, CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height), screenshotImage);
            CGImageRelease(screenshotImage);

            outImage = CGBitmapContextCreateImage(context);
            CGContextRelease(context);
            
            if (colorSpace) CFRelease(colorSpace);

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
                [weakSelf _updateThumbnailImage:thumbnail];
            });
        }
    });
}


#pragma mark - Accessors

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
