//
//  CaptureManager.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-27.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ScreenCaptureMode) {
    ScreenCaptureModeNone = 0,

    ScreenCaptureModeRectangle,
    ScreenCaptureModeWindow,
    ScreenCaptureModeEntireScreen
};

@protocol ScreenCaptureDelegate;


@interface ScreenCapture : NSObject

@property (nonatomic, weak) id<ScreenCaptureDelegate> delegate;

- (void) startCaptureWithMode:(ScreenCaptureMode)mode;
- (void) cancel;

@property (nonatomic, readonly) ScreenCaptureMode mode;

- (void) mouseLocationDidChange:(CGPoint)point;

@end


@protocol ScreenCaptureDelegate <NSObject>
- (void) screenCapture:(ScreenCapture *)screenCapture didCaptureImage:(NSImage *)image;
- (void) screenCapture:(ScreenCapture *)screenCapture didUpdateMode:(ScreenCaptureMode)mode;
@end