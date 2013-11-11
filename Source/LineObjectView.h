//
//  GuideLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@class Line;

@interface LineObjectView : CanvasObjectView
@property (nonatomic, strong) Line *line;
@end
