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
    BOOL _selected;
}


- (void) drawRect:(NSRect)dirtyRect
{
    NSImage *thumbnail = [_libraryItem thumbnail];

    CGSize maxSize = GetMaxThumbnailSize();

    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGRect thumbnailRect;

    {
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowColor:GetRGBColor(0x0, 1.0)];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:2];

        [shadow set];
    }

    if (thumbnail) {
        NSRect bounds = [self bounds];

        NSSize fromSize = [thumbnail size];
        NSRect fromRect = NSZeroRect;
        fromRect.size = fromSize;

        thumbnailRect = NSZeroRect;
        thumbnailRect.size = fromSize;
        thumbnailRect.origin.x = round((bounds.size.width  - thumbnailRect.size.width)  / 2);
        thumbnailRect.origin.y = round((bounds.size.height - thumbnailRect.size.height) / 2);

        [thumbnail drawInRect:thumbnailRect fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];

    } else {
        CGImageRef screenshot = [[_libraryItem screenshot] CGImage];
    
    
    
        CGContextSaveGState(context);
        CGContextDrawImage(context, [self bounds], screenshot);

        CGContextRestoreGState(context);
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
