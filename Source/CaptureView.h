//
//  CaptureView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-07.
//
//

#import <Foundation/Foundation.h>

@protocol CaptureViewDelegate;


@interface CaptureView : NSView

- (id) initWithImage:(CGImageRef)image;

@property (weak) id<CaptureViewDelegate> delegate;

@end


@protocol CaptureViewDelegate <NSObject>
- (void) captureView:(CaptureView *)view didCaptureRect:(CGRect)rect;
@end