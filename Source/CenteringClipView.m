// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "CenteringClipView.h"
#import "RulerView.h"


@implementation CenteringClipView


- (NSView *) hitTest:(NSPoint)aPoint
{
    NSView *result = [super hitTest:aPoint];
    if (!result) result = [self documentView];
    return result;
}


- (void) scrollToPoint:(NSPoint)newOrigin
{
    [super scrollToPoint:newOrigin];

    [_horizontalRulerView setOffset:-newOrigin.x];
    [_verticalRulerView   setOffset:-newOrigin.y];
}


- (NSRect) constrainBoundsRect:(NSRect)proposedBounds
{
    NSRect documentFrame = [[self documentView] frame];
    NSRect selfBounds    = [self bounds];

    CGFloat maxX = documentFrame.size.width  - selfBounds.size.width;
    CGFloat maxY = documentFrame.size.height - selfBounds.size.height;

    selfBounds.origin = proposedBounds.origin;

    if (documentFrame.size.width < selfBounds.size.width) {
        selfBounds.origin.x = round(maxX / 2.0);
    } else {
        selfBounds.origin.x = round(MAX(0, MIN(selfBounds.origin.x, maxX)));
    }

    if (documentFrame.size.height < selfBounds.size.height) {
        selfBounds.origin.y = round(maxY / 2.0);
    } else {
        selfBounds.origin.y = round(MAX(0, MIN(selfBounds.origin.y, maxY)));
    }

    proposedBounds.origin = NSMakePoint(
        documentFrame.origin.x + selfBounds.origin.x,
        documentFrame.origin.y + selfBounds.origin.y
    );
    
    return proposedBounds;
}


@end
