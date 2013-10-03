//
//  MarqueeLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-30.
//
//

#import <Foundation/Foundation.h>

#import "CanvasLayer.h"

@class Marquee;

@interface MarqueeLayer : CanvasLayer
@property (nonatomic, strong) Marquee *marquee;
@end
