//
//  BlackSegmentedControl.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import <Foundation/Foundation.h>

@interface BlackSegmentedControl : NSSegmentedControl

- (void) setTemplateImage:(NSImage *)image forSegment:(NSInteger)segment;
- (NSImage *) templateImageForSegment:(NSInteger)segment;

@end

@interface BlackSegmentedCell : NSSegmentedCell

@end