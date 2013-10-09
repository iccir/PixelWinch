//
//  GuideLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasLayer.h"

@class Grapple;

@interface GrappleLayer : CanvasLayer
@property (nonatomic, strong) Grapple *grapple;
@end
