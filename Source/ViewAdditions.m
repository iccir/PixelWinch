//
//  Compatibility.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2016-11-05.
//
//

#import "ViewAdditions.h"


@implementation NSView (XUIKitAdditions_Implementation)

+ (void) load
{
    Class cls = [NSView class];

    WinchAliasMethod(cls, '-', @selector(winch_bringSubviewToFront:),                       @selector(bringSubviewToFront:));
    WinchAliasMethod(cls, '-', @selector(winch_sendSubviewToBack:),                         @selector(sendSubviewToBack:));
    WinchAliasMethod(cls, '-', @selector(winch_insertSubview:atIndex:),                     @selector(insertSubview:atIndex:));
    WinchAliasMethod(cls, '-', @selector(winch_insertSubview:belowSubview:),                @selector(insertSubview:belowSubview:));
    WinchAliasMethod(cls, '-', @selector(winch_insertSubview:aboveSubview:),                @selector(insertSubview:aboveSubview:));
    WinchAliasMethod(cls, '-', @selector(winch_exchangeSubviewAtIndex:withSubviewAtIndex:), @selector(exchangeSubviewAtIndex:withSubviewAtIndex:));
    WinchAliasMethod(cls, '-', @selector(winch_isDescendantOfView:),                        @selector(isDescendantOfView:));
    WinchAliasMethod(cls, '-', @selector(winch_setNeedsDisplay),                            @selector(setNeedsDisplay));
    WinchAliasMethod(cls, '-', @selector(winch_setNeedsLayout),                             @selector(setNeedsLayout));
}


- (void) winch_bringSubviewToFront:(NSView *)view
{
    [view removeFromSuperview];
    [self addSubview:view];  
}


- (void) winch_sendSubviewToBack:(NSView *)view
{
    [view removeFromSuperview];
    
    NSArray *subviews = [self subviews];
    if ([subviews count]) {
        NSView *firstSubview = [subviews objectAtIndex:0];
        [self addSubview:view positioned:NSWindowBelow relativeTo:firstSubview];
    } else {
        [self addSubview:view];
    }
}


- (void) winch_insertSubview:(NSView *)view atIndex:(NSInteger)index
{
    [view removeFromSuperview];
    
    NSMutableArray *subviews = [[self subviews] mutableCopy];
    [subviews insertObject:view atIndex:index];
    [self setSubviews:subviews];
}


- (void) winch_insertSubview:(NSView *)view belowSubview:(NSView *)siblingSubview
{
    [self addSubview:view positioned:NSWindowBelow relativeTo:siblingSubview];
}


- (void) winch_insertSubview:(NSView *)view aboveSubview:(NSView *)siblingSubview
{
    [self addSubview:view positioned:NSWindowAbove relativeTo:siblingSubview];
}


- (void) winch_exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2
{
    NSMutableArray *subviews = [[self subviews] mutableCopy];
    [subviews exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    [self setSubviews:subviews];
}


- (BOOL) winch_isDescendantOfView:(NSView *)view
{
    return [self isDescendantOf:view];
}


- (void) winch_setNeedsDisplay
{
    [self setNeedsDisplay:YES];
}


- (void) winch_setNeedsLayout
{
    [self setNeedsLayout:YES];
}


@end


