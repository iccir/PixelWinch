//
//  Compatibility.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2016-11-05.
//
//

@import Foundation;


@interface NSView (CompatibilityAdditions)

- (void) bringSubviewToFront:(NSView *)view;
- (void) sendSubviewToBack:(NSView *)view;

- (void) insertSubview:(NSView *)view atIndex:(NSInteger)index;
- (void) insertSubview:(NSView *)view belowSubview:(NSView *)siblingSubview;
- (void) insertSubview:(NSView *)view aboveSubview:(NSView *)siblingSubview;
- (void) exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2;

- (BOOL) isDescendantOfView:(NSView *)view;

- (void) setNeedsDisplay;   // Calls setNeedsDisplay:YES
- (void) setNeedsLayout;    // Calls setNeedsLayout:YES

@end


