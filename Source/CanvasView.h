//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "BaseView.h"


@class CanvasObjectView, Canvas, MeasurementLabel;
@protocol CanvasViewDelegate;


@interface CanvasView : BaseView

- (id) initWithFrame:(NSRect)frameRect canvas:(Canvas *)canvas;

- (void) addCanvasObjectView:(CanvasObjectView *)view;
- (void) removeCanvasObjectView:(CanvasObjectView *)view;
- (void) updateCanvasObjectView:(CanvasObjectView *)view;

- (MeasurementLabel *) measurementLabelWithGUID:(NSString *)GUID;
- (void) makeVisibleAndPopInLabelForView:(CanvasObjectView *)view;

- (void) sizeToFit;

- (void) invalidateCursors;

- (NSImage *) snapshotImageWithCanvasRect:(CGRect)rect;

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

- (CanvasObjectView *) duplicateObjectView:(CanvasObjectView *)objectView;

- (void) objectViewDoubleClick:(CanvasObjectView *)objectView;

- (BOOL) shouldTrackObjectView:(CanvasObjectView *)objectView;
- (void) willTrackObjectView:(CanvasObjectView *)objectView;
- (void) didTrackObjectView:(CanvasObjectView *)objectView;
@end


@protocol CanvasViewDelegate <NSObject>
- (NSCursor *) cursorForCanvasView:(CanvasView *)view ;

- (CanvasObjectView *) canvasView:(CanvasView *)view duplicateObjectView:(CanvasObjectView *)objectView;

- (void) canvasView:(CanvasView *)view objectViewDoubleClick:(CanvasObjectView *)objectView;

- (void) canvasView:(CanvasView *)view didFinalizeNewbornWithView:(CanvasObjectView *)objectView;

- (BOOL) canvasView:(CanvasView *)view shouldTrackObjectView:(CanvasObjectView *)objectView;
- (void) canvasView:(CanvasView *)view willTrackObjectView:(CanvasObjectView *)objectView;
- (void) canvasView:(CanvasView *)view didTrackObjectView:(CanvasObjectView *)objectView;

- (void) canvasView:(CanvasView *)view mouseMovedWithEvent:(NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseExitedWithEvent:(NSEvent *)event;

- (BOOL) canvasView:(CanvasView *)view mouseDownWithEvent:   (NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseDraggedWithEvent:(NSEvent *)event;
- (void) canvasView:(CanvasView *)view mouseUpWithEvent:     (NSEvent *)event;
- (void) canvasView:(CanvasView *)view flagsChangedWithEvent:(NSEvent *)event;

@end

