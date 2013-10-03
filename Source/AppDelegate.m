//
//  PixelsAppDelegate.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2011-05-01.
//  Copyright 2011 Stellar Squid, LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "ScreenCapture.h"
#import "CanvasController.h"
#import "WinchWindowController.h"

static NSString * const sStateKey = @"State";

static NSString * const sLaserStateKey     = @"Lasers";
static NSString * const sGuideStateKey     = @"Guides";
static NSString * const sMagnifierStateKey = @"Magnifier";

static NSTimeInterval const sLaserThreshold = 1.0;

@interface AppDelegate () <ScreenCaptureDelegate>
- (void) _updateMouseTracking;
@end


@implementation AppDelegate {
    id _globalHandler;
    id _localHandler;
    
    ScreenCapture *_screenCapture;
    CGPoint _lastMouseLocation;
    NSTimeInterval _lastMouseTimeInterval;
    NSTimer *_mouseTrackingTimer;

    NSInteger _hotKeyCount;
    
    WinchWindowController *_winchController;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) _setupDefaults
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
//
//
//    [dictionary setObject:@"key,@1" forKey:<#(id)#>
//    
//    [dictionary setObject:yes forKey:LaserShowBoundariesKey];
//    [dictionary setObject:no  forKey:LaserShowAspectRatioKey];
//
//    [dictionary setObject:no  forKey:LoupeViewAlwaysHideKey];
//    [dictionary setObject:[NSNumber numberWithInteger:5]  forKey:LoupeViewZoomKey];
//    [dictionary setObject:[NSNumber numberWithInteger:10] forKey:LoupeViewSizeKey];
//
//    [dictionary setObject:yes forKey:LoupeColorAlwaysHideKey];
//    [dictionary setObject:[NSNumber numberWithInteger:7]  forKey:LoupeColorZoomKey];
//    [dictionary setObject:[NSNumber numberWithInteger:10] forKey:LoupeColorSizeKey];
//
//    [dictionary setObject:yes forKey:GuidesRequireModifierKey];
//    [dictionary setObject:no  forKey:GuidesModifierKey];
//
//    [dictionary setObject:yes forKey:MagnifierShouldFloatKey];
//    [dictionary setObject:[NSNumber numberWithInteger:8] forKey:MagnifierZoomLevelKey];

    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}


- (void) _resetHotKeycount
{
    _hotKeyCount = 0;
}


- (void) _mouseTrackingTick:(NSTimer *)timer
{
    CGPoint mouseLocation = [NSEvent mouseLocation];
    NSTimeInterval now    = [NSDate timeIntervalSinceReferenceDate];
    BOOL didMouseMove     = (_lastMouseLocation.x != mouseLocation.x) || (_lastMouseLocation.y != mouseLocation.y);
    BOOL needsUpdateTick  = (now - _lastMouseTimeInterval > 0.5);

    if (didMouseMove) {
        _lastMouseLocation = mouseLocation;
        _lastMouseTimeInterval = now;
    }
    
    if (didMouseMove || needsUpdateTick) {
        [_screenCapture mouseLocationDidChange:mouseLocation];
    }
}




- (void) _incrementHotKeyCount:(NSEventType)eventType
{
    BOOL isDown = (eventType == NSFlagsChanged);
    if (isDown) _hotKeyCount++;
    else if (_hotKeyCount) _hotKeyCount++;
    
    if (_hotKeyCount == 4) {
        _hotKeyCount = 0;
        [_screenCapture startCaptureWithMode:ScreenCaptureModeRectangle];
    }
    
    [self performSelector:@selector(_resetHotKeycount) withObject:nil afterDelay:1];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    __weak id weakSelf = self;

    _screenCapture = [[ScreenCapture alloc] init];
    [_screenCapture setDelegate:self];

    void (^handler)(NSEvent *) = ^(NSEvent *event) {
        if ([event keyCode] == 63) {
            [weakSelf _incrementHotKeyCount:[event type]];
        }
    };

    _globalHandler = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask handler:^(NSEvent *event) {
        handler(event);
    }];

    _localHandler = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask handler:^(NSEvent *event) {
        handler(event);
        return event;
    }];


    _mouseTrackingTimer = [NSTimer timerWithTimeInterval:(1.0 / 60.0) target:self selector:@selector(_mouseTrackingTick:) userInfo:nil repeats:YES];

    [[NSRunLoop currentRunLoop] addTimer:_mouseTrackingTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] addTimer:_mouseTrackingTimer forMode:NSEventTrackingRunLoopMode];

    [self _mouseTrackingTick:_mouseTrackingTimer];

    _winchController = [[WinchWindowController alloc] init];
    [_winchController showWindow:self];
}

- (void) screenCapture:(ScreenCapture *)screenCapture didCaptureImage:(NSImage *)image
{

}


- (void) screenCapture:(ScreenCapture *)screenCapture didUpdateMode:(ScreenCaptureMode)mode
{
}


@end
