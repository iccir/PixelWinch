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

- (void) zoom;
- (void) zoomIn;
- (void) zoomOut;

- (void) zoomToMagnificationLevel:(CGFloat)magnificationLevel;

// Applies key modifier masks
- (BOOL) calculatedZoomsIn;

- (NSInteger) magnificationIndexForLevel:(CGFloat)magnificationLevel;

@property BOOL zoomsIn;
@property NSInteger magnificationIndex;

@property (readonly) CGFloat magnificationLevel;
@property (readonly) NSString *magnificationString;

@end
