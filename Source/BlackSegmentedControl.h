//
//  BlackSegmentedControl.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import <Foundation/Foundation.h>

@interface BlackSegmentedControl : NSSegmentedControl

- (void) setSelectedImage:(NSImage *)image forSegment:(NSInteger)segment;
- (NSImage *) selectedImageForSegment:(NSInteger)segment;

@end

@interface BlackSegmentedCell : NSSegmentedCell

@end