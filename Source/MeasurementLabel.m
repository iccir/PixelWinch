//
//  MeasurementLabel.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-10.
//
//

#import "MeasurementLabel.h"
#import "CanvasObject.h"


@interface MeasurementLabel () <CALayerDelegate>
@end


@implementation MeasurementLabel {
    NSFont        *_font;
    NSDictionary  *_attributes;
    CALayer       *_sublayer;
    NSString      *_currentText;
}


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _sublayer = [CALayer layer];
        [_sublayer setDelegate:self];
        [_sublayer setNeedsDisplay];
        
        [[self layer] addSublayer:_sublayer];
    }
    
    return self;
}


- (NSFont *) _font
{
    if (!_font) {
        _font = [NSFont userFontOfSize:13];
    }

    return _font;
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
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        [ps setLineSpacing:0];
        [ps setMaximumLineHeight:[[self _font] pointSize] + 1];
        [ps setAlignment:NSTextAlignmentCenter];
        
        _attributes = @{
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSFontAttributeName: [self _font],
            NSParagraphStyleAttributeName: ps
        };
    }
    
    return _attributes;
}


- (void) doPopInAnimationWithDuration:(CGFloat)duration
{
    AddPopInAnimation(_sublayer, duration);
}


- (void) layoutSubviews
{
    [_sublayer setFrame:[self bounds]];
}


- (BOOL) layer:(CALayer *)layer shouldInheritContentsScale:(CGFloat)newScale fromWindow:(NSWindow *)window
{
    [[self layer] setContentsScale:newScale];
    [_sublayer setContentsScale:newScale];

    return YES;
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == _sublayer) {
        NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES]];
    
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
        
        WithWhiteOnBlackTextMode(^{
            [shadow set];
            [[self _text] drawAtPoint:NSMakePoint(padding.width, padding.height) withAttributes:attributes];
        });

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
