//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "BottomShadowView.h"

@interface BottomShadowView () <CALayerDelegate>
@end


@implementation BottomShadowView

- (id) initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        CALayer *selfLayer = [CALayer layer];
        [selfLayer setDelegate:self];
        
        [self setWantsLayer:YES];
        [self setLayer:selfLayer];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];

        [[self layer] setNeedsDisplay];
    }

    return self;
}

- (BOOL) wantsUpdateLayer
{
    return YES;
}


- (void) updateLayer
{
    [[self layer] setContents:[NSImage imageNamed:@"BottomShadow"]];
    [self setLayerContentsPlacement:NSViewLayerContentsPlacementScaleAxesIndependently];
}

@end
