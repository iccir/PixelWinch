// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "Tool.h"


@interface ZoomTool : Tool

// Applies key modifier masks
- (BOOL) calculatedZoomsIn;

@property (nonatomic) BOOL zoomsIn;
@property (nonatomic, getter=isInTemporaryMode) BOOL inTemporaryMode;


@end
