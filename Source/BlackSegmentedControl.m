//
//  BlackSegmentedControl.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "BlackSegmentedControl.h"


@implementation BlackSegmentedControl {
    NSMutableDictionary *_segmentNumberToImageMap;
    NSMutableDictionary *_segmentNumberToGradientMap;
}

- (void) setTemplateImage:(NSImage *)image forSegment:(NSInteger)segment
{
    if (!_segmentNumberToImageMap) {
        _segmentNumberToImageMap = [NSMutableDictionary dictionary];
    }
    
    [_segmentNumberToImageMap setObject:image forKey:@(segment)];
    
    [self setNeedsDisplay];
}


- (NSImage *) templateImageForSegment:(NSInteger)segment
{
    return [_segmentNumberToImageMap objectForKey:@(segment)];
}


- (void) setSelectedGradient:(NSGradient *)gradient forSegment:(NSInteger)segment
{
    if (!_segmentNumberToGradientMap) {
        _segmentNumberToGradientMap = [NSMutableDictionary dictionary];
    }
    
    [_segmentNumberToGradientMap setObject:gradient forKey:@(segment)];
}


- (NSGradient *) selectedGradientForSegment:(NSInteger)segment
{
    return [_segmentNumberToGradientMap objectForKey:@(segment)];
}


@end


@implementation BlackSegmentedCell {
    NSMutableDictionary *_segmentToFrameMap;
}

- (void) drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(BlackSegmentedControl *)controlView
{
    [_segmentToFrameMap setObject:[NSValue valueWithRect:frame] forKey:@(segment)];
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(BlackSegmentedControl *)controlView
{
    _segmentToFrameMap = [NSMutableDictionary dictionary];
    
    [super drawWithFrame:cellFrame inView:controlView];

    NSRectFillListUsingOperation(&cellFrame, 1, NSCompositingOperationClear);

    NSRect shadowFrame = cellFrame;
    shadowFrame.size.height -= 1.0;

    CGContextRef context = GetCurrentGraphicsContext();

    NSInteger segmentCount = [controlView segmentCount];
    for (NSInteger i = 0; i < segmentCount; i++) {
        BOOL isSelected = [controlView isSelectedForSegment:i];
        CGRect frame = [[_segmentToFrameMap objectForKey:@(i)] rectValue];

        if (isSelected) {
            CGRect roundedRect = [[_segmentToFrameMap objectForKey:@(i)] rectValue];
            roundedRect.origin.y    = cellFrame.origin.y;
            roundedRect.size.height = cellFrame.size.height - 1;

            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:roundedRect xRadius:6 yRadius:6];

            NSGradient *g = [[NSGradient alloc] initWithColors:@[
                GetRGBColor(0xffffff, 0.1),
                GetRGBColor(0xffffff, 0.15)
            ]];
            
            [g drawInBezierPath:path angle:90];
        }

        NSImage *image = [controlView templateImageForSegment:i];

        NSSize imageSize = [image size];
        NSRect imageRect = { frame.origin, imageSize };

        imageRect.origin.y = cellFrame.origin.y;
        imageRect.origin.x += round((frame.size.width  - imageSize.width)  / 2);
        imageRect.origin.y += round(((cellFrame.size.height - 1) - imageSize.height) / 2);

        CGContextSaveGState(context);

        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowBlurRadius:(isSelected ? 4 : 2)];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        [shadow setShadowColor:[NSColor blackColor]];
        
        [shadow set];
        
        CGContextBeginTransparencyLayer(context, NULL);

        ClipToImage(image, imageRect);

        NSGradient *g;

        if (isSelected) {
            g = [controlView selectedGradientForSegment:i];
    
            if (!g) {
                g = [[NSGradient alloc] initWithColors:@[
                    GetRGBColor(0xfffff0, 1.0),
                    GetRGBColor(0xffffff, 1.0)
                ]];
            }

        } else {
            g = [[NSGradient alloc] initWithColors:@[
                GetRGBColor(0xb0b0b0, 1.0),
                GetRGBColor(0x989898, 1.0)
            ]];
        }
        
        [g drawInRect:imageRect angle:90];

        CGContextEndTransparencyLayer(context);

        CGContextRestoreGState(context);

    }

    _segmentToFrameMap = nil;
}



@end
