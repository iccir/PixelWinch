//  (c) 2013-2017, Ricci Adams.  All rights reserved.


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
