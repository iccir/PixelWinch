//
//  ShadowView.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-29.
//
//

#import "ShadowView.h"

@implementation ShadowView

- (void) layout
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] cornerRadius:_cornerRadius];
    [[self layer] setShadowPath:[path CGPath]];
}


- (void) updateLayer
{
    CALayer *layer = [self layer];

    NSColor *shadowColor = [_shadow shadowColor];
    
    [layer setCornerRadius:_cornerRadius];
    
    if (shadowColor) {
        [layer setShadowColor:[[shadowColor colorWithAlphaComponent:1.0] CGColor]];
        [layer setShadowOpacity:[shadowColor alphaComponent]];
        [layer setShadowRadius:[_shadow shadowBlurRadius]];
        [layer setShadowOffset:[_shadow shadowOffset]];
    } else {
        [layer setShadowOpacity:0];
    }
}



- (void) setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [self updateLayer];
    }
}


- (void) setShadow:(NSShadow *)shadow
{
    if (_shadow != shadow) {
        _shadow = shadow;
        [self updateLayer];
    }
}
@end
