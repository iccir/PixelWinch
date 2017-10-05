//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "OverlayBaseView.h"

@implementation OverlayBaseView

- (instancetype) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setFlipped:NO];
    }

    return self;
}


- (void) mouseUp:(NSEvent *)theEvent
{
    [_delegate overlayBaseView:self clickedWithEvent:theEvent];
}


- (void) setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [[self layer] setCornerRadius:cornerRadius];
    }
}


@end
