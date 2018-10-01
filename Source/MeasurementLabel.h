//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import <Cocoa/Cocoa.h>

#import "CanvasObjectView.h"

@interface MeasurementLabel : BaseView

@property (nonatomic, weak) CanvasObjectView *owningObjectView;

- (void) updateText;
- (void) doPopInAnimationWithDuration:(CGFloat)duration;

- (CGSize) neededSize;

@property (nonatomic, getter=isSelected) BOOL selected;

@end
