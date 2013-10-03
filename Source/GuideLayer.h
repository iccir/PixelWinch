//
//  GuideLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasLayer.h"

@class Guide;

@interface GuideLayer : CanvasLayer
@property (nonatomic, strong) Guide *guide;
@end
