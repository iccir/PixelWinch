//
//  CanvasLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>

@class CanvasObject;

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


@property (nonatomic, strong) CanvasObject *canvasObject;

@end
