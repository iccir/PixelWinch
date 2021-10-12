//
//  SegmentedCell.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2021-10-12.
//

#import "ToolbarSegmentedControl.h"

@implementation ToolbarSegmentedControl

@end


@implementation ToolbarSegmentedCell {
    NSMutableDictionary *_segmentToFrameMap;
}

- (void) drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(ToolbarSegmentedControl *)controlView
{
    [_segmentToFrameMap setObject:[NSValue valueWithRect:frame] forKey:@(segment)];
}


- (void) drawWithFrame:(NSRect)cellFrame inView:(ToolbarSegmentedControl *)controlView
{
    _segmentToFrameMap = [NSMutableDictionary dictionary];
    
    [super drawWithFrame:cellFrame inView:controlView];

    NSRectFillListUsingOperation(&cellFrame, 1, NSCompositingOperationClear);

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    

    NSRect unionFrame = NSZeroRect;
    for (NSValue *frameValue in [_segmentToFrameMap allValues]) {
        unionFrame = NSUnionRect(unionFrame, [frameValue rectValue]);
    }
    unionFrame.origin.y    = cellFrame.origin.y;
    unionFrame.size.height = cellFrame.size.height - 1;

    NSBezierPath *unionPath = [NSBezierPath bezierPathWithRoundedRect:unionFrame xRadius:6 yRadius:6];
    [[NSColor colorNamed:@"SegmentedBackground"] set];
    [unionPath fill];

    NSInteger segmentCount = [controlView segmentCount];
    for (NSInteger i = 0; i < segmentCount; i++) {
        BOOL isSelected = [controlView isSelectedForSegment:i];
        CGRect frame = [[_segmentToFrameMap objectForKey:@(i)] rectValue];

        if (isSelected) {
            CGRect roundedRect = [[_segmentToFrameMap objectForKey:@(i)] rectValue];
            roundedRect.origin.y    = unionFrame.origin.y;
            roundedRect.size.height = unionFrame.size.height;

            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:roundedRect xRadius:6 yRadius:6];

            [[NSColor colorNamed:@"SegmentedBackgroundSelected"] set];
            
            [path fill];
        }

        NSImage *image = [controlView imageForSegment:i];

        NSSize imageSize = [image size];
        NSRect imageRect = { frame.origin, imageSize };

        imageRect.origin.y = cellFrame.origin.y;
        imageRect.origin.x += round((frame.size.width       - imageSize.width)  / 2);
        imageRect.origin.y += round((unionFrame.size.height - imageSize.height) / 2);

        CGContextBeginTransparencyLayer(context, NULL);
        {
            [image drawInRect:imageRect];

            if (isSelected) {
                [[NSColor colorNamed:@"SegmentedIconSelected"] set];
            } else {
                [[NSColor colorNamed:@"SegmentedIcon"] set];
            }

            NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        }
        CGContextEndTransparencyLayer(context);
    }

    _segmentToFrameMap = nil;
}


@end
