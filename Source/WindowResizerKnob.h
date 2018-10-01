//  (c) 2015-2018, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@protocol WindowResizerKnobDelegate;


@interface WindowResizerKnob : NSView
@property (nonatomic, weak) id<WindowResizerKnobDelegate> delegate;
@end


@protocol WindowResizerKnobDelegate <NSObject>
- (void) windowResizerKnobWillStartDrag:(WindowResizerKnob *)knob ;
- (void) windowResizerKnob:(WindowResizerKnob *)knob didDragWithDeltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY;
- (void) windowResizerKnobWillEndDrag:(WindowResizerKnob *)knob ;
@end
