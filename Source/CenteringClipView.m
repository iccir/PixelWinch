//
//  CenteringClipView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-04.
//
//

#import "CenteringClipView.h"

@implementation CenteringClipView

- (NSPoint) _centeredPointForPoint:(NSPoint)inPoint
{
    NSRect docRect  = [[self documentView] frame];
    NSRect clipRect = [self bounds];

    CGFloat maxX = docRect.size.width - clipRect.size.width;
    CGFloat maxY = docRect.size.height - clipRect.size.height;

    clipRect.origin = inPoint; // shift origin to proposed location

    // If the clip view is wider than the doc, we can't scroll horizontally
    if (docRect.size.width < clipRect.size.width) {
        clipRect.origin.x = round( maxX / 2.0 );
    } else {
        clipRect.origin.x = round( MAX(0,MIN(clipRect.origin.x,maxX)) );
    }

    // If the clip view is taller than the doc, we can't scroll vertically
    if (docRect.size.height < clipRect.size.height) {
        clipRect.origin.y = round( maxY / 2.0 );
    } else {
        clipRect.origin.y = round( MAX(0,MIN(clipRect.origin.y,maxY)) );
    }
//
//    // Save center of view as proportions so we can later tell where the user was focused.
//    mLookingAt.x = NSMidX(clipRect) / docRect.size.width;
//    mLookingAt.y = NSMidY(clipRect) / docRect.size.height;

    // The docRect isn't necessarily at (0, 0) so when it isn't, this correctly creates the correct scroll point
    return NSMakePoint(docRect.origin.x + clipRect.origin.x, docRect.origin.y + clipRect.origin.y);
}


- (NSRect) constrainBoundsRect:(NSRect)proposedBounds
{
    proposedBounds.origin = [self _centeredPointForPoint:proposedBounds.origin];
    return proposedBounds;
}


- (NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin
{
    return [self _centeredPointForPoint:proposedNewOrigin];
}

@end
