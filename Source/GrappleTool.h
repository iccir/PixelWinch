// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "Tool.h"

@interface GrappleTool : Tool

+ (BOOL) isEnabled;

// Applies key modifier masks
- (BOOL) calculatedIsVertical;

- (void) updatePreviewGrapple;

- (void) toggleVertical;

@property (nonatomic) BOOL attachesToGuides;
@property (nonatomic, getter=isVertical) BOOL vertical;

@end
