//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import <Cocoa/Cocoa.h>

@protocol RulerViewDelegate;

@interface RulerView : NSView
@property (nonatomic, weak) IBOutlet id<RulerViewDelegate> delegate;

@property (nonatomic, getter=isVertical) BOOL vertical;
@property (nonatomic) CGFloat offset;
@property (nonatomic) CGFloat magnification;

@end


@protocol RulerViewDelegate <NSObject>
- (BOOL) rulerView:(RulerView *)view mouseDownWithEvent:(NSEvent *)event;
@end
