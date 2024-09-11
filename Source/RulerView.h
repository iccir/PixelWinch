// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Cocoa/Cocoa.h>

@protocol RulerViewDelegate;

@interface RulerView : NSView
@property (nonatomic, weak) IBOutlet id<RulerViewDelegate> delegate;

@property (nonatomic, getter=isVertical) BOOL vertical;
@property (nonatomic) CGFloat offset;
@property (nonatomic) CGFloat magnification;

@end


@interface RulerCornerView : NSView
@end


@protocol RulerViewDelegate <NSObject>
- (BOOL) rulerView:(RulerView *)view mouseDownWithEvent:(NSEvent *)event;
@end
