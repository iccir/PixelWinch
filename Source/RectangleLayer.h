//
//  RectangleLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasLayer.h"

@class Rectangle;

@interface RectangleLayer : CanvasLayer
@property (nonatomic, strong) Rectangle *rectangle;
@end
