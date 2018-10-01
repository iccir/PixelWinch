//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "BaseView.h"

@protocol OverlayBaseViewDelegate;

@interface OverlayBaseView : BaseView
@property (nonatomic, weak) id<OverlayBaseViewDelegate> delegate;
@property (nonatomic, assign) CGFloat cornerRadius;
@end

@protocol OverlayBaseViewDelegate <NSObject>
- (void) overlayBaseView:(OverlayBaseView *)view clickedWithEvent:(NSEvent *)event;
@end
