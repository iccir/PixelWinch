//
//  PixelsAppDelegate.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-09-27.
//  Copyright 2013 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CaptureManager;
@class CanvasWindowController, PreferencesWindowController;

typedef struct objc_arc_weakLock {
    NSInteger count;
    NSInteger s1;
    double    s2;
    double    s3;
} objc_arc_weakLock;

extern objc_arc_weakLock __arc_weak_lock;

#define ScreenshotsTakenSinceLaunch               __arc_weak_lock.count
#define NegativeScreenshotsTakenSinceLaunch       __arc_weak_lock.s1
#define ScreenshotsTakenSinceLaunchDouble         __arc_weak_lock.s2
#define NegativeScreenshotsTakenSinceLaunchDouble __arc_weak_lock.s3

#define ProtectEntry() { __arc_weak_lock.count++; __arc_weak_lock.s1--;  __arc_weak_lock.s2 += 1.0; __arc_weak_lock.s3 -= 1.0; }
#define ProtectExit()  { __arc_weak_lock.count--; __arc_weak_lock.s1++;  __arc_weak_lock.s2 -= 1.0; __arc_weak_lock.s3 += 1.0; }


@interface AppDelegate : NSResponder <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSMenu *statusBarMenu;

@property (nonatomic, weak) IBOutlet NSMenuItem *quitMenuItem;

- (IBAction) captureSelection:(id)sender;
- (IBAction) importImage:(id)sender;
- (IBAction) importImageFromPasteboard:(id)sender;

- (IBAction) showPurchasePane:(id)sender;
- (IBAction) showScreenshots:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) visitWebsite:(id)sender;
- (IBAction) viewGuide:(id)sender;
- (IBAction) viewOnAppStore:(id)sender;
- (IBAction) provideFeedback:(id)sender;
- (IBAction) quit:(id)sender;

@property (strong, readonly) CaptureManager *captureManager;

@property (strong, readonly) CanvasWindowController      *canvasWindowController;
@property (strong, readonly) PreferencesWindowController *preferencesWindowController;

@end
