//
//  MeasurementLabel.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-10.
//
//

#import <Cocoa/Cocoa.h>

#import "CanvasObjectView.h"

@interface MeasurementLabel : BaseView

@property (nonatomic, weak) CanvasObjectView *owningObjectView;

- (void) updateText;
- (void) doPopInAnimationWithDuration:(CGFloat)duration;

- (CGSize) neededSize;

@property (nonatomic, getter=isSelected) BOOL selected;

@end
