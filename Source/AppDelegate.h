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

@interface AppDelegate : NSResponder <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSMenu *statusBarMenu;

@property (nonatomic, weak) IBOutlet NSMenuItem *quitMenuItem;

- (IBAction) captureSelection:(id)sender;
- (IBAction) importImage:(id)sender;
- (IBAction) importImageFromPasteboard:(id)sender;

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
