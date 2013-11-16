//
//  Canvas.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Cocoa/Cocoa.h>

@class CanvasObjectView, Canvas;
@protocol CanvasViewDelegate;


@interface CanvasView : XUIView

- (id) initWithFrame:(NSRect)frameRect canvas:(Canvas *)canvas;

- (void) addCanvasObjectView:(CanvasObjectView *)view;
- (void) removeCanvasObjectView:(CanvasObjectView *)view;
- (void) updateCanvasObjectView:(CanvasObjectView *)view;

- (void) makeVisibleAndPopInLabelForView:(CanvasObjectView *)view;

- (void) sizeToFit;

- (void) invalidateCursors;

@property (nonatomic, readonly) Canvas *canvas;

@property (nonatomic, weak) id<CanvasViewDelegate> IBOutlet delegate;

- (CGPoint) canvasPointForPoint:(CGPoint)point;
- (CGPoint) canvasPointForEvent:(NSEvent *)event;

- (CGPoint) roundedCanvasPointForPoint:(CGPoint)point;
- (CGPoint) roundedCanvasPointForEvent:(NSEvent *)event;

- (CGPoint) canvasPointAtCenter;
- (BOOL) convertMouseLocationToCanvasPoint:(CGPoint *)outPoint;

- (void) setMagnification:(CGFloat)magnification centeredAtCanvasPoint:(NSPoint)point;
- (void) setMagnification:(CGFloat)magnification pinnedAtCanvasPoint:(NSPoint)point;
@property (nonatomic, assign) CGFloat magnification;

@end


@interface CanvasView (CalledByCanvasObjectViews)
- (BOOL) shouldTrackObjectView:(CanvasObjectView *)objectView;
- (void) willTrackObjectView:(CanvasObjectView *)objectView;
- (void) didTrackObjectView:(CanvasObjectView *)objectView;
@end


@protocol CanvasViewDelegate <NSObject>
- (NSCursor *) cursorForCanvasView:(CanvasView *)view ;

- (BOOL) canvasView:(CanvasView *)view shouldTrackObjectView:(CanvasObjectView *)objectView;
- (void) canvasView:(CanvasView *)view willTrackObjectView:(CanvasObjectView *)objectView;
- (void) canvasView:(CanvasView *)view didTrackObjectView:(CanvasObjectView *)objectView;

- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseExitedWithEvent:(NSEvent *)event;

- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:   (NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseDraggedWithEvent:(NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseUpWithEvent:     (NSEvent *)event;

@end

