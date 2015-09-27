//
//  ZoomTool.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import <Foundation/Foundation.h>
#import "Tool.h"


@interface ZoomTool : Tool

// Applies key modifier masks
- (BOOL) calculatedZoomsIn;

@property (nonatomic) BOOL zoomsIn;
@property (nonatomic, getter=isInTemporaryMode) BOOL inTemporaryMode;


@end
