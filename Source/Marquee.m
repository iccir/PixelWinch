// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "Marquee.h"
#import "Canvas.h"
#import "Screenshot.h"


@implementation Marquee

+ (NSString *) groupName
{
    return @"marquee";
}


- (BOOL) isValid
{
    CGSize size = [self rect].size;
    return size.width > 0 || size.height > 0;
}


- (BOOL) writeToPasteboard:(NSPasteboard *)pasteboard
{
    if ([self isValid]) {
        CGImageRef cgImage    = [[[self canvas] screenshot] CGImage];
        CGImageRef cgSubimage = CGImageCreateWithImageInRect(cgImage, [self rect]);

        if (!cgSubimage) return NO;

        CGFloat scale = [[[NSScreen screens] firstObject] backingScaleFactor];

        NSImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgSubimage];

        NSSize imageSize = NSMakeSize(
            [rep pixelsWide] / scale,
            [rep pixelsHigh] / scale
        );
        
        NSImage *image = [[NSImage alloc] initWithSize:imageSize];
        [image addRepresentations:@[ rep ] ];

        [pasteboard clearContents];
        [pasteboard writeObjects:@[ image ]];
        
        CGImageRelease(cgSubimage);
        
        return YES;

    } else {
        return NO;
    }
}


- (BOOL) participatesInUndo
{
    return NO;
}


- (BOOL) isPersistent
{
    return NO;
}



@end
