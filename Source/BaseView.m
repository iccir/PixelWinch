//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "BaseView.h"

#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>

@interface BaseView () <CALayerDelegate>
@end


@implementation BaseView {
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
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    [self setWantsLayer:YES];
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
    return YES;
}

- (void) updateLayer { }


- (BOOL) isFlipped
{
    return YES;
}


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




@end

