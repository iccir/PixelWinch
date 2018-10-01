//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>
#import "Tool.h"


@interface ZoomTool : Tool

// Applies key modifier masks
- (BOOL) calculatedZoomsIn;

@property (nonatomic) BOOL zoomsIn;
@property (nonatomic, getter=isInTemporaryMode) BOOL inTemporaryMode;


@end
