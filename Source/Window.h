//
//  Window.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-07.
//
//

#import <Foundation/Foundation.h>

@protocol WindowDelegate;


@interface Window : NSWindow

- (void) setDelegate:(id<WindowDelegate>)anObject;
- (id<WindowDelegate>) delegate;

- (void) setCanBecomeKeyWindow:(BOOL)canBecomeKeyWindow;
- (void) setCanBecomeMainWindow:(BOOL)canBecomeMainWindow;

@end

@protocol WindowDelegate <NSWindowDelegate>
@optional
- (BOOL) window:(Window *)window cancelOperation:(id)sender;
@end