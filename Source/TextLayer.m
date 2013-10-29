//
//  TextLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-10.
//
//

#import "TextLayer.h"

@implementation TextLayer {
    CALayer *_sublayer;
    CGSize _dimensions;
    NSFont *_font;
    
    NSString *_text;
    TextLayerStyle _textLayerStyle;
    NSDictionary *_attributes;
}

- (id) init
{
    if (self = [super init]) {
        _sublayer = [CALayer layer];
        [_sublayer setNeedsDisplayOnBoundsChange:YES];
        [_sublayer setDelegate:self];
        [_sublayer setOpaque:NO];

        [self addSublayer:_sublayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
    }

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSFont *) _font
{
    if (!_font) {
        _font =  [NSFont userFontOfSize:13];
    }

    return _font;
}

- (NSDictionary *) _attributes
{
    if (!_attributes) {
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        [ps setLineSpacing:0];
        [ps setMaximumLineHeight:[[self _font] pointSize] + 1];
        [ps setAlignment:NSCenterTextAlignment];
        
        _attributes = @{
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSFontAttributeName: [self _font],
            NSParagraphStyleAttributeName: ps
        };
    }
    
    return _attributes;
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if (layer == _sublayer) {
        NSDictionary *attributes = [self _attributes];
        
        NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:YES]];
        
        NSRect rect = [_text boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
        NSSize size = rect.size;

        [[NSColor colorWithCalibratedWhite:0 alpha:0.75] set];
        
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
        
        WithWhiteOnBlackTextMode(^{
            [_text drawAtPoint:NSMakePoint(padding.width, padding.height) withAttributes:attributes];
        });
        
        [NSGraphicsContext setCurrentContext:savedContext];
    }

}

- (void) layoutSublayers
{
    [super layoutSublayers];
    
    CGRect bounds = [self bounds];

    [_sublayer setContentsScale:[[self superlayer] contentsScale]];

    NSRect rect = [_text boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:[self _attributes]];
    CGSize size = rect.size;

    size.height = ceil(size.height);
    size.width  = ceil(size.width);

    CGRect sublayerFrame = { CGPointZero, size };
    sublayerFrame.origin.x = round((bounds.size.width - sublayerFrame.size.width) / 2);
    sublayerFrame.origin.y = round((bounds.size.height - sublayerFrame.size.height) / 2);

    sublayerFrame = CGRectInset(sublayerFrame, -6, -2);
    [_sublayer setFrame:sublayerFrame];
}


- (void) _updateText
{
    NSString *text;
    
    if (_textLayerStyle == TextLayerStyleBoth) {
        text = GetStringForSize(_dimensions);
    } else if (_textLayerStyle == TextLayerStyleWidthOnly) {
        text = GetStringForFloat(_dimensions.width);
    } else if (_textLayerStyle == TextLayerStyleHeightOnly) {
        text = GetStringForFloat(_dimensions.height);
    }
    
    if (![_text isEqualToString:text]) {
        _text = text;
        [self setNeedsLayout];
        [_sublayer setNeedsDisplay];
    }
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    [self _updateText];
    [self setNeedsLayout];
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return [[self delegate] actionForLayer:self forKey:event];
}


- (void) setDimensions:(CGSize)dimensions
{
    @synchronized(self) {
        if (!CGSizeEqualToSize(_dimensions, dimensions)) {
            _dimensions = dimensions;
            [self _updateText];
        }
    }
}


- (CGSize) dimensions
{
    @synchronized(self) {
        return _dimensions;
    }
}


- (void) setTextLayerStyle:(TextLayerStyle)textLayerStyle
{
    @synchronized(self) {
        if (_textLayerStyle != textLayerStyle) {
            _textLayerStyle = textLayerStyle;
            [self _updateText];
        }
    }
}


- (TextLayerStyle) textLayerStyle
{
    @synchronized(self) {
        return _textLayerStyle;
    }
}


@end
