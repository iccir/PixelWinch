// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Cocoa/Cocoa.h>

@class CaptureManager;
@class CanvasWindowController, PreferencesWindowController;

@interface AppDelegate : NSResponder <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSMenu *statusBarMenu;

@property (nonatomic, weak) IBOutlet NSMenuItem *quitMenuItem;

@property (nonatomic, weak) IBOutlet NSMenu *viewMenu;

- (IBAction) captureSelection:(id)sender;
- (IBAction) importImage:(id)sender;
- (IBAction) importImageFromPasteboard:(id)sender;

- (IBAction) showScreenshots:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) visitWebsite:(id)sender;
- (IBAction) viewGuide:(id)sender;
- (IBAction) provideFeedback:(id)sender;
- (IBAction) quit:(id)sender;

@property (strong, readonly) CaptureManager *captureManager;

@property (strong, readonly) CanvasWindowController      *canvasWindowController;
@property (strong, readonly) PreferencesWindowController *preferencesWindowController;

@end
