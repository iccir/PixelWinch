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

    NSRect shadowFrame = cellFrame;
    shadowFrame.size.height -= 1.0;

    NSInteger count = [controlView segmentCount];
    for (NSInteger i = 0; i < [controlView segmentCount]; i++) {
        BOOL isSelected = [controlView isSelectedForSegment:i];
        CGRect frame = [[_segmentToFrameMap objectForKey:@(i)] rectValue];

        SegmentShape shape = SegmentShapeMiddle;
        if (i == 0) shape = SegmentShapeLeft;
        else if (i == (count - 1)) shape = SegmentShapeRight;

        NSImage *segmentImage = sGetSegmentImage(shape, NO, isSelected);

        frame.origin.x -= 1.0;
        frame.origin.y    = cellFrame.origin.y;
        frame.size.height = [segmentImage size].height;
        frame.size.width += 1.0;

        if (shape == SegmentShapeRight) {
            frame.size.width += 1.0;
        }
        
        DrawThreePart(segmentImage, frame, 5, 5);

        NSImage *image;
        if (isSelected) {
            image = [controlView selectedImageForSegment:i];
        } else {
            image = [controlView imageForSegment:i];
        }

        NSSize imageSize = [image size];
        NSRect imageRect = { frame.origin, imageSize };

        imageRect.origin.y = cellFrame.origin.y;
        imageRect.origin.x += round((frame.size.width  - imageSize.width)  / 2);
        imageRect.origin.y += round(((cellFrame.size.height - 1) - imageSize.height) / 2);

        [image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
    }

    _segmentToFrameMap = nil;
}



@end