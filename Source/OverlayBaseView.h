//
//  ShroudView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "BaseView.h"

@protocol OverlayBaseViewDelegate;

@interface OverlayBaseView : BaseView
@property (nonatomic, weak) id<OverlayBaseViewDelegate> delegate;
@property (nonatomic, assign) CGFloat cornerRadius;
@end

@protocol OverlayBaseViewDelegate <NSObject>
- (void) overlayBaseView:(OverlayBaseView *)view clickedWithEvent:(NSEvent *)event;
@end
