//
//  CenteringClipView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-04.
//
//

#import "CenteringClipView.h"
#import "RulerView.h"


@implementation CenteringClipView {
    NSColor *_backgroundColor;
}


- (void) _commonInit
{
    [self setWantsLayer:YES];
    [self setLayer:[CAScrollLayer layer]];
    [[self layer] setDelegate:self];
    
	[self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
    [self setOpaque:NO];
}


+ (void) initialize
{
    if (![NSClipView instancesRespondToSelector:@selector(constrainBoundsRect:)]) {
        XUIAliasMethod([CenteringClipView class], '-', @selector(legacy_constrainScrollPoint:), @selector(constrainScrollPoint:));
    }
}


- (id) initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
        [self _commonInit];
    }

    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self _commonInit];
    }
    
    return self;
}


- (NSView *) hitTest:(NSPoint)aPoint
{
    NSView *result = [super hitTest:aPoint];
    if (!result) result = [self documentView];
    return result;
}


- (NSPoint) _centeredPointForPoint:(NSPoint)inPoint
{
    NSRect documentFrame = [[self documentView] frame];
    NSRect selfBounds    = [self bounds];

    CGFloat maxX = documentFrame.size.width  - selfBounds.size.width;
    CGFloat maxY = documentFrame.size.height - selfBounds.size.height;

    selfBounds.origin = inPoint;

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


    NSPoint result = NSMakePoint(
        documentFrame.origin.x + selfBounds.origin.x,
        documentFrame.origin.y + selfBounds.origin.y
    );

    return result;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id)[NSNull null];
}


- (void)scrollToPoint:(NSPoint)newOrigin
{
    [super scrollToPoint:newOrigin];

    [_horizontalRulerView setOffset:-newOrigin.x];
    [_verticalRulerView   setOffset:-newOrigin.y];
}


- (NSRect) constrainBoundsRect:(NSRect)proposedBounds
{
    proposedBounds.origin = [self _centeredPointForPoint:proposedBounds.origin];
    return proposedBounds;
}


- (NSPoint) legacy_constrainScrollPoint:(NSPoint)proposedNewOrigin
{
    return [self _centeredPointForPoint:proposedNewOrigin];
}


- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor;
        [[self layer] setBackgroundColor:[backgroundColor CGColor]];
    }
}


- (NSColor *) backgroundColor
{
    return _backgroundColor;
}


- (void) setOpaque:(BOOL)opaque
{
	[[self layer] setOpaque:opaque];
}


- (BOOL) isOpaque
{
	return [[self layer] isOpaque];
}


@end
