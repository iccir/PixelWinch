// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Cocoa/Cocoa.h>

#import "CanvasObjectView.h"

@interface MeasurementLabel : NSView

@property (nonatomic, weak) CanvasObjectView *owningObjectView;

- (void) updateText;
- (void) doPopInAnimationWithDuration:(CGFloat)duration;

- (CGSize) neededSize;

@property (nonatomic, getter=isSelected) BOOL selected;

@end
