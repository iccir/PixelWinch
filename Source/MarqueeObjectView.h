//
//  MarqueeLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-30.
//
//

#import <Foundation/Foundation.h>

#import "CanvasObjectView.h"

@class Marquee;

@interface MarqueeObjectView : CanvasObjectView
@property (nonatomic, strong) Marquee *marquee;
@end
