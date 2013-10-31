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

@property (nonatomic) NSInteger tolerance;
@property (nonatomic) BOOL attachesToGuides;
@property (nonatomic, getter=isVertical) BOOL vertical;

@end
