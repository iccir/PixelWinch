//
//  PixelsAppDelegate.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-09-27.
//  Copyright 2013 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CaptureController, PreferencesController, WinchWindowController;

@interface AppDelegate : NSResponder <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSMenu *statusBarMenu;

- (IBAction) captureSelection:(id)sender;
- (IBAction) captureWindow:(id)sender;
- (IBAction) showScreenshots:(id)sender;
- (IBAction) showPreferences:(id)sender;

@property (strong, readonly) CaptureController     *captureController;
@property (strong, readonly) PreferencesController *preferencesController;
@property (strong, readonly) WinchWindowController *winchController;

@end
