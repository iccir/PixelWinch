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

typedef NS_ENUM(NSInteger, MeasurementLabelStyle) {
    MeasurementLabelStyleNone = 0,
    MeasurementLabelStyleWidthOnly,
    MeasurementLabelStyleHeightOnly,
    MeasurementLabelStyleBoth
};


typedef NS_ENUM(NSInteger, CanvasOrder) {
    CanvasOrderNormal      =     0,

    CanvasOrderRectangle   =  500,
    CanvasOrderPreviewLine =  501,
    CanvasOrderLine        =  502,

    CanvasOrderResizeKnob  =  900,

    CanvasOrderMarquee     =  1000,
    CanvasOrderGuide       =  1001,
};


@interface CanvasObjectView : XUIView

- (CanvasView *) canvasView;

- (void) preferencesDidChange:(Preferences *)preferences;

- (void) trackWithEvent:(NSEvent *)event newborn:(BOOL)newborn;
- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) switchTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point;

- (NSCursor *) cursor;

- (CGRect) rectForCanvasLayout;
- (XUIEdgeInsets) paddingForCanvasLayout;
- (NSArray *) resizeKnobEdges; // Subclasses to override

- (NSInteger) canvasOrder;
- (MeasurementLabelStyle) measurementLabelStyle;
- (BOOL) isMeasurementLabelHidden;

@property (nonatomic, strong) CanvasObject *canvasObject;
@property (nonatomic, getter=isNewborn) BOOL newborn;
@property (nonatomic, getter=isSelected) BOOL selected;

// When space bar is down during a drag
@property (nonatomic) BOOL    inMoveMode;
@property (nonatomic) CGPoint pointWhenEnteredMoveMode;
@property (nonatomic) CGRect  canvasObjectRectWhenEnteredMoveMode;

@end
