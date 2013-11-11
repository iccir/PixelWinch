//
//  PixelsAppDelegate.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-09-27.
//  Copyright 2013 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CanvasController, CaptureController, PreferencesController;

@interface AppDelegate : NSResponder <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSMenu *statusBarMenu;

- (IBAction) captureSelection:(id)sender;
- (IBAction) showScreenshots:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) provideFeedback:(id)sender;
- (IBAction) quit:(id)sender;

@property (strong, readonly) CanvasController      *canvasController;
@property (strong, readonly) CaptureController     *captureController;
@property (strong, readonly) PreferencesController *preferencesController;

@end
