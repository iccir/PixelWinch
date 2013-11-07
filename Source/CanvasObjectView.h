//
//  CanvasLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasView.h"

@class CanvasObject, CanvasView;

typedef NS_ENUM(NSInteger, ResizeKnobType) {
    ResizeKnobTopLeft,     ResizeKnobTop,     ResizeKnobTopRight,
    ResizeKnobLeft,                           ResizeKnobRight,
    ResizeKnobBottomLeft,  ResizeKnobBottom,  ResizeKnobBottomRight
};


typedef NS_ENUM(NSInteger, CanvasOrder) {
    CanvasOrderNormal         =     0,

    CanvasOrderRectangle      =  500,
    CanvasOrderPreviewGrapple =  501,
    CanvasOrderGrapple        =  502,

    CanvasOrderResizeKnob     =  900,

    CanvasOrderMarquee        =  1000,
    CanvasOrderGuide          =  1001,
};


@interface CanvasObjectView : XUIView

- (CanvasView *) canvasView;

- (void) preferencesDidChange:(Preferences *)preferences;

- (void) trackWithEvent:(NSEvent *)event newborn:(BOOL)newborn;
- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;

- (NSCursor *) cursor;

- (CGRect) rectForCanvasLayout;
- (XUIEdgeInsets) paddingForCanvasLayout;
- (NSArray *) resizeKnobTypes; // Subclasses to override

- (CGPoint) snappedPointForEvent:(NSEvent *)event;
- (CGPoint) snappedPointForPoint:(CGPoint)inPoint;

- (SnappingPolicy) horizontalSnappingPolicy;
- (SnappingPolicy) verticalSnappingPolicy;

- (NSInteger) canvasOrder;

@property (nonatomic, strong) CanvasObject *canvasObject;
@property (nonatomic, getter=isNewborn) BOOL newborn;
@property (nonatomic, getter=isSelected) BOOL selected;

@end
