//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@interface BlackSegmentedControl : NSSegmentedControl

- (void) setSelectedGradient:(NSGradient *)gradient forSegment:(NSInteger)segment;
- (NSGradient *) selectedGradientForSegment:(NSInteger)segment;

- (void) setTemplateImage:(NSImage *)image forSegment:(NSInteger)segment;
- (NSImage *) templateImageForSegment:(NSInteger)segment;

@end

@interface BlackSegmentedCell : NSSegmentedCell

@end
