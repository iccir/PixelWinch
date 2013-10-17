//
//  GrappleTool.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "Tool.h"

@interface GrappleTool : Tool

// Applies key modifier masks
- (BOOL) calculatedIsVertical;

- (UInt8) calculatedThreshold;

@property NSInteger tolerance;
@property BOOL attachesToGuides;
@property (getter=isVertical) BOOL vertical;

@end
