//
//  Window.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-07.
//
//

#import <Foundation/Foundation.h>

@protocol CanvasWindowDelegate;


@interface CanvasWindow : NSWindow

- (void) setDelegate:(id<CanvasWindowDelegate>)anObject;
- (id<CanvasWindowDelegate>) delegate;

@end

@protocol CanvasWindowDelegate <NSWindowDelegate>
@optional
- (BOOL) window:(CanvasWindow *)window performClose:(id)sender;
- (BOOL) window:(CanvasWindow *)window cancelOperation:(id)sender;
@end