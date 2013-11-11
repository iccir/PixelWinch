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

- (void) centerScrollViewOnLastEventPoint;

- (NSInteger) magnificationIndexForLevel:(CGFloat)magnificationLevel;

@property (nonatomic) BOOL zoomsIn;
@property (nonatomic) NSInteger magnificationIndex;

@property (nonatomic, readonly) CGFloat magnificationLevel;
@property (nonatomic, readonly) NSString *magnificationString;

@end
