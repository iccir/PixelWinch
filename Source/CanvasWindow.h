// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
