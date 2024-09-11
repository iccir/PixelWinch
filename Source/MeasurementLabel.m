// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "MeasurementLabel.h"
#import "CanvasObject.h"


@interface MeasurementLabel () <CALayerDelegate, NSViewLayerContentScaleDelegate>
@end


@implementation MeasurementLabel {
    NSDictionary  *_attributes;
    CALayer       *_sublayer;
}


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setWantsLayer:YES];

        _sublayer = [CALayer layer];
        [_sublayer setDelegate:self];
        [_sublayer setNeedsDisplay];
        
        [[self layer] addSublayer:_sublayer];
    }
    
    return self;
}


- (BOOL) isFlipped
{
    return YES;
}


- (void) mouseDown:(NSEvent *) event
{
    if ([self owningObjectView]) {
        [[self owningObjectView] mouseDown:event];
        return;
    }
    
    [super mouseDown:event];
}


- (NSDictionary *) _attributes
{
    if (!_attributes) {
        NSFont *font = [NSFont userFontOfSize:13];
    
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        [ps setLineSpacing:0];
        [ps setMaximumLineHeight:[font pointSize] + 1];
        [ps setAlignment:NSTextAlignmentCenter];
        
        _attributes = @{
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSFontAttributeName: font,
            NSParagraphStyleAttributeName: ps
        };
    }
    
    return _attributes;
}


- (void) doPopInAnimationWithDuration:(CGFloat)duration
{
    CAKeyframeAnimation *transform = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CABasicAnimation    *opacity   = [CABasicAnimation animationWithKeyPath:@"opacity"];

    [transform setValues:@[
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5,  0.5,  1)],
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1,  1.1,  1)],
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0,  1.0,  1)],
    ]];
    
    [transform setKeyTimes:@[
        @(0.0),
        @(0.5),
        @(0.9),
        @(1.0)
    ]];

    [transform setDuration:duration];
    [opacity   setDuration:duration];
    
    [opacity setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [opacity setFromValue:@(0)];
    [opacity setToValue:@(1)];
    
    [_sublayer addAnimation:transform forKey:@"popIn"];
    [_sublayer addAnimation:opacity forKey:@"opacity"];
}


- (void) layout
{
    [_sublayer setFrame:[self bounds]];
}


- (void) viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    [self _inheritContentsScaleFromWindow:[self window]];
}


- (BOOL) layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window
{
    [self _inheritContentsScaleFromWindow:window];
    return YES;
}


- (void) _inheritContentsScaleFromWindow:(NSWindow *)window
{
    CGFloat contentsScale = [window backingScaleFactor];

    if (contentsScale) {
        [_sublayer setContentsScale:contentsScale];
    }
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == _sublayer) {
        NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:context flipped:YES]];
    
        NSString *text = [self _text];
        NSDictionary *attributes = [self _attributes];
        
        NSRect rect = [text boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
        NSSize size = rect.size;

        if (_selected) {
            [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.66 alpha:1.0] set];
        } else {
            [[NSColor colorWithCalibratedWhite:0 alpha:0.75] set];
        }

        CGSize padding = NSMakeSize(6, 2);
        
        size.width  = ceil(size.width)  + (2 * padding.width);
        size.height = ceil(size.height) + (2 * padding.height);

        CGFloat radius = size.width < size.height ? size.width : size.height;
        radius /= 2;
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height) xRadius:radius yRadius:radius];
        [path fill];

        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow setShadowBlurRadius:2];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        
        [shadow set];
        [[self _text] drawAtPoint:NSMakePoint(padding.width, padding.height) withAttributes:attributes];

        [NSGraphicsContext setCurrentContext:savedContext];
    }
}


- (CGSize) neededSize
{
    NSRect rect = [[self _text] boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:[self _attributes]];
    CGSize size = rect.size;

    return CGSizeMake(
        ceil(size.width ) + (2 * 6),
        ceil(size.height) + (2 * 2)
    );
}


- (void) updateText
{
    [self setNeedsLayout:YES];
    [_sublayer setNeedsDisplay];
}


- (NSString *) _text
{
    NSString *text;
    
    CanvasObjectView *canvasObjectView = [self owningObjectView];
    CGSize size = [[canvasObjectView canvasObject] rect].size;
    
    MeasurementLabelStyle style = [canvasObjectView measurementLabelStyle];

    if (style == MeasurementLabelStyleBoth) {
        text = GetDisplayStringForSize(size);
    } else if (style == MeasurementLabelStyleWidthOnly) {
        text = GetStringForFloat(size.width);
    } else if (style == MeasurementLabelStyleHeightOnly) {
        text = GetStringForFloat(size.height);
    }

    return text;
}


- (void) setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [_sublayer setNeedsDisplay];
    }
}


@end
