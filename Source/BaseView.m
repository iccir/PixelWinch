/*
    Copyright (c) 2012-2013, Ricci Adams.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following condition is met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL RICCI ADAMS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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

