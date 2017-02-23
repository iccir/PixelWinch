//
//  ShadowView.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-29.
//
//

#import "OverlayShadowView.h"

@implementation OverlayShadowView


- (instancetype) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setLayer:[CALayer layer]];
    }

    return self;
}


- (void) layoutSubviews
{
    [super layoutSubviews];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:_cornerRadius yRadius:_cornerRadius];

    CGPathRef shadowPath = CopyPathWithBezierPath(path);
    [[self layer] setShadowPath:shadowPath];
    CGPathRelease(shadowPath);
}


- (void) updateLayer
{
    CALayer *layer = [self layer];

    NSColor *shadowColor = [[self shadow] shadowColor];
    
    [layer setCornerRadius:_cornerRadius];
    
    if (shadowColor) {
        [layer setShadowColor:[[shadowColor colorWithAlphaComponent:1.0] CGColor]];
        [layer setShadowOpacity:[shadowColor alphaComponent]];
        [layer setShadowRadius:[[self shadow] shadowBlurRadius]];
        [layer setShadowOffset:[[self shadow] shadowOffset]];
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


@end
