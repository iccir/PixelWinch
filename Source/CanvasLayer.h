//
//  CanvasLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>

@class CanvasObject;

enum {
    CanvasOrderPreviewGrapple = -1000,
    CanvasOrderNormal         =     0,

    CanvasOrderRectangle      =  500,
    CanvasOrderGrapple        =  501,

    CanvasOrderResizeKnob     =  900,

    CanvasOrderMarquee        =  1000,
    CanvasOrderGuide          =  1001,
};

typedef NS_ENUM(NSInteger, SnappingPolicy) {
    SnappingPolicyNone,
    SnappingPolicyToPixelEdge,
    SnappingPolicyToPixelCenter
};

@interface CanvasLayer : CALayer

- (void) preferencesDidChange:(Preferences *)preferences;

- (BOOL) mouseDownWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point;
- (void) mouseUpWithEvent:(NSEvent *)event point:(CGPoint)point;

- (NSCursor *) cursor;

- (CGRect) rectForCanvasLayout;
- (NSEdgeInsets) paddingForCanvasLayout;

- (SnappingPolicy) verticalSnappingPolicy;
- (SnappingPolicy) horizontalSnappingPolicy;

- (NSInteger) canvasOrder;

@property (nonatomic, strong) CanvasObject *canvasObject;
@property (nonatomic, assign, getter=isNewborn) BOOL newborn;

@end
