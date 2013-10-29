//
//  ResizeKnobLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@interface ResizeKnobView : CanvasObjectView

@property (nonatomic, weak) CanvasObjectView *canvasObjectView;
@property (nonatomic) ResizeKnobType type;

@end
