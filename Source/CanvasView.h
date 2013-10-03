//
//  Canvas.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Cocoa/Cocoa.h>

@class CanvasLayer, Canvas;
@protocol CanvasViewDelegate;

@interface CanvasView : NSView

- (id) initWithFrame:(NSRect)frameRect canvas:(Canvas *)canvas;

- (void) addCanvasLayer:(CanvasLayer *)layer;
- (void) removeCanvasLayer:(CanvasLayer *)layer;
- (void) updateCanvasLayer:(CanvasLayer *)layer;
- (CanvasLayer *) canvasLayerWithPoint:(CGPoint)point;


- (void) invalidateCursorRects;

@property (nonatomic, readonly) Canvas *canvas;

@property (nonatomic, weak) id<CanvasViewDelegate> delegate;

- (CGPoint) pointForMouseEvent:(NSEvent *)event;
- (CGPoint) pointForMouseEvent:(NSEvent *)event layer:(CanvasLayer *)layer;

@property (nonatomic, assign) CGFloat magnification;

@end

@protocol CanvasViewDelegate <NSObject>
- (NSCursor *) cursorForCanvasView:(CanvasView *)view ;

- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) canvasView:(CanvasView *)view mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) canvasView:(CanvasView *)view mouseUpWithEvent:  (NSEvent *)event point:(CGPoint)point;

@end

