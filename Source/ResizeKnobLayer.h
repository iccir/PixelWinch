//
//  ResizeKnobLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>
#import "CanvasLayer.h"

typedef NS_ENUM(NSInteger, ResizeKnobType) {
    ResizeKnobTopLeft,
    ResizeKnobTop,
    ResizeKnobTopRight,
    
    ResizeKnobLeft,
    ResizeKnobRight,

    ResizeKnobBottomLeft,
    ResizeKnobBottom,
    ResizeKnobBottomRight
};


@interface ResizeKnobLayer : CanvasLayer

@property (nonatomic, weak) CanvasLayer *parentLayer;
@property (nonatomic) ResizeKnobType type;

@end
