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


typedef NS_ENUM(NSInteger, SnappingPolicy) {
    SnappingPolicyNone,
    SnappingPolicyToPixelEdge,
    SnappingPolicyToPixelCenter
};

@interface CanvasView : XUIView

- (id) initWithFrame:(NSRect)frameRect canvas:(Canvas *)canvas;

- (void) addCanvasObjectView:(CanvasObjectView *)layer;
- (void) removeCanvasObjectView:(CanvasObjectView *)layer;
- (void) updateCanvasObjectView:(CanvasObjectView *)layer;

- (void) sizeToFit;

- (void) invalidateCursors;

@property (nonatomic, readonly) Canvas *canvas;

@property (nonatomic, weak) id<CanvasViewDelegate> IBOutlet delegate;

- (CGPoint) canvasPointForPoint: (CGPoint) point;
- (CGPoint) canvasPointForEvent: (NSEvent *) event;

- (CGPoint) canvasPointForPoint: (CGPoint) point
       horizontalSnappingPolicy: (SnappingPolicy) horizontalSnappingPolicy
         verticalSnappingPolicy: (SnappingPolicy) verticalSnappingPolicy;

- (CGPoint) canvasPointForEvent: (NSEvent *) event
       horizontalSnappingPolicy: (SnappingPolicy) horizontalSnappingPolicy
         verticalSnappingPolicy: (SnappingPolicy) verticalSnappingPolicy;

@property (nonatomic, assign) CGFloat magnification;

@property (nonatomic, assign) BOOL hidesGuides;

@end

@interface CanvasView (CalledByCanvasObjectViews)
- (BOOL) shouldTrackObjectView:(CanvasObjectView *)objectView;
- (void) didTrackObjectView:(CanvasObjectView *)objectView;
@end

@protocol CanvasViewDelegate <NSObject>
- (NSCursor *) cursorForCanvasView:(CanvasView *)view ;

- (BOOL) canvasView:(CanvasView *)view shouldTrackObjectView:(CanvasObjectView *)objectView;
- (void) canvasView:(CanvasView *)view didTrackObjectView:(CanvasObjectView *)objectView;

- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseExitedWithEvent:(NSEvent *)event;

- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:   (NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseDraggedWithEvent:(NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseUpWithEvent:     (NSEvent *)event;

@end

