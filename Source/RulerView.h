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
@property (nonatomic, weak) id<RulerViewDelegate> delegate;
@end


@protocol RulerViewDelegate <NSObject>
- (BOOL) rulerView:(RulerView *)view mouseDownWithEvent:(NSEvent *)event;
- (void) rulerView:(RulerView *)view mouseDragWithEvent:(NSEvent *)event;
- (void) rulerView:(RulerView *)view mouseUpWithEvent:  (NSEvent *)event;
@end
