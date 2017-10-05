//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "BaseView.h"

#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>

@interface BaseView () <CALayerDelegate>
@end


@implementation BaseView {
    BOOL _implementsDrawRect;
}

@synthesize tag = _tag, flipped = _flipped;


static IMP sBaseView_drawRect = NULL;

+ (void) initialize
{
    if (self == [BaseView class]) {
        sBaseView_drawRect = [self instanceMethodForSelector:@selector(drawRect:)];
    }
}


#pragma mark - Lifecycle

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self _commonBaseViewInit];
    }

    return self;
}


- (id) initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        [self _commonBaseViewInit];
    }
    
    return self;
}


- (void) _commonBaseViewInit
{
    IMP selfDrawRect = [[self class] instanceMethodForSelector:@selector(drawRect:)];
    _implementsDrawRect = (selfDrawRect != sBaseView_drawRect);

    NSViewLayerContentsRedrawPolicy redrawPolicy = _implementsDrawRect ?
        NSViewLayerContentsRedrawOnSetNeedsDisplay :
        NSViewLayerContentsRedrawDuringViewResize;

    [self setLayerContentsRedrawPolicy:redrawPolicy];
    [self setWantsLayer:YES];
    [self setFlipped:YES];
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setAutoresizesSubviews:NO];

    if (_implementsDrawRect) {
        [[self layer] setNeedsDisplay];
    }
    
    [self setClipsToBounds:NO];
}


- (void) dealloc
{
    [[self layer] setDelegate:nil];
}


#pragma mark - Superclass Overrides

- (CALayer *) makeBackingLayer
{
    CALayer *layer = [CALayer layer];
    [layer setDelegate:self];
    return layer;
}


- (BOOL) wantsUpdateLayer
{
    return !_implementsDrawRect;
}

- (void) updateLayer { }


#pragma mark - Hierarchy

- (void) didAddSubview:(NSView *)subview
{
    [super didAddSubview:subview];
    [self setNeedsLayout:YES];
}


- (void) willRemoveSubview:(NSView *)subview
{
    [super willRemoveSubview:subview];
    [self setNeedsLayout:YES];
}


- (void) layout
{
    if (@available(macOS 10.12, *)) {
        // In 10.12, we no longer need to call [super layout]
    } else {
        [super layout];
    }

    [self layoutSubviews];
}

- (void) layoutSubviews { }

- (void) drawRect:(CGRect)rect { }


#pragma mark - Accessors

@dynamic clipsToBounds;

- (void) setBackgroundColor:(NSColor *)backgroundColor
{
    if (_backgroundColor != backgroundColor) {
        _backgroundColor = backgroundColor;
        [[self layer] setBackgroundColor:[backgroundColor CGColor]];
    }
}


- (void) setClipsToBounds:(BOOL)clipsToBounds
{
    [[self layer] setMasksToBounds:clipsToBounds];
}


- (BOOL) clipsToBounds
{
    return [[self layer] masksToBounds];
}


@end

