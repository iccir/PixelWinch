//
//  GrappleTool.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "Tool.h"

@interface GrappleTool : Tool

+ (BOOL) isEnabled;

// Applies key modifier masks
- (BOOL) calculatedIsVertical;

- (void) updatePreviewGrapple;

- (void) toggleVertical;

@property (nonatomic) NSInteger tolerance;
@property (nonatomic) BOOL attachesToGuides;
@property (nonatomic, getter=isVertical) BOOL vertical;

@end
