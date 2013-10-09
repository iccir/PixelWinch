//
//  BlackSegmentedControl.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "BlackSegmentedControl.h"

typedef NS_ENUM(NSInteger, SegmentShape) {
    SegmentShapeLeft,
    SegmentShapeMiddle,
    SegmentShapeRight
};


static NSImage *sGetSegmentImage(SegmentShape shape, BOOL highlighted, BOOL selected)
{
    NSString *shapeName = @"middle";
    if (shape == SegmentShapeLeft) {
        shapeName = @"left";
    } else if (shape == SegmentShapeRight) {
        shapeName = @"right";
    }

    NSString *stateName = @"normal";
    if (selected) {
        stateName = @"selected";
    } else if (highlighted) {
        stateName = @"highlighted";
    }

    NSString *imageName = [NSString stringWithFormat:@"segmented_%@_%@", shapeName, stateName];
    return [NSImage imageNamed:imageName];
}


@implementation BlackSegmentedControl {
    NSMutableDictionary *_segmentNumberToImageMap;
}

- (void) setSelectedImage:(NSImage *)image forSegment:(NSInteger)segment
{
    if (!_segmentNumberToImageMap) {
        _segmentNumberToImageMap = [NSMutableDictionary dictionary];
    }
    
    [_segmentNumberToImageMap setObject:image forKey:@(segment)];
}

- (NSImage *) selectedImageForSegment:(NSInteger)segment
{
    return [_segmentNumberToImageMap objectForKey:@(segment)];
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

    NSRectFillListUsingOperation(&cellFrame, 1, NSCompositeClear);

    for (NSInteger i = 0; i < [controlView segmentCount]; i++) {
        CGRect frame = [[_segmentToFrameMap objectForKey:@(i)] rectValue];

        NSImage *image;
        if ([controlView isSelectedForSegment:i]) {
            image = [controlView selectedImageForSegment:i];
        } else {
            image = [controlView imageForSegment:i];
        }

        NSSize imageSize = [image size];
        NSRect imageRect = { frame.origin, imageSize };

        imageRect.origin.x += round((frame.size.width  - imageSize.width)  / 2);
        imageRect.origin.y += round((frame.size.height - imageSize.height) / 2);

        [image drawInRect:imageRect];
    }

    _segmentToFrameMap = nil;
}



@end