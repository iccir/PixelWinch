//
//  GuideLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@class Guide;

@interface GuideObjectView : CanvasObjectView
@property (nonatomic, strong) Guide *guide;
@end
