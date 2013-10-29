//
//  RectangleLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@class Rectangle;

@interface RectangleObjectView : CanvasObjectView
@property (nonatomic, strong) Rectangle *rectangle;
@end
