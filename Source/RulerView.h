//
//  CanvasRulerView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import <Cocoa/Cocoa.h>

@protocol RulerViewDelegate;

@interface RulerView : NSView
@property (nonatomic, weak) IBOutlet id<RulerViewDelegate> delegate;

@property (nonatomic, getter=isVertical) BOOL vertical;
@property (atomic) CGFloat offset;
@property (atomic) CGFloat magnification;

@end


@protocol RulerViewDelegate <NSObject>
- (BOOL) rulerView:(RulerView *)view mouseDownWithEvent:(NSEvent *)event;
@end
