//
//  GuideLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@class Grapple;

@interface GrappleObjectView : CanvasObjectView
@property (nonatomic, strong) Grapple *grapple;

@property (assign) UInt8   originalThreshold;
@property (assign) BOOL    originalStopsOnGuides;

@end
