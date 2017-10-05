//  (c) 2013-2017, Ricci Adams.  All rights reserved.


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
