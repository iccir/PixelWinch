//
//  ShroudView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-09.
//
//

#import <Cocoa/Cocoa.h>

@protocol ShroudViewDelegate;

@interface ShroudView : NSView
@property (weak) id<ShroudViewDelegate> delegate;

@property (strong) NSColor *backgroundColor;
@property (assign) CGFloat cornerRadius;

@end

@protocol ShroudViewDelegate <NSObject>
- (void) shroudView:(ShroudView *)shroudView clickedWithEvent:(NSEvent *)event;
@end