//
//  ShroudView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import "BaseView.h"

@protocol ContentViewDelegate;

@interface ContentView : BaseView
@property (nonatomic, weak) id<ContentViewDelegate> delegate;
@property (nonatomic, assign) CGFloat cornerRadius;
@end

@protocol ContentViewDelegate <NSObject>
- (void) contentView:(ContentView *)view clickedWithEvent:(NSEvent *)event;
@end
