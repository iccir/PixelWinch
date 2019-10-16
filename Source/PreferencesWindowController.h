//  (c) 2011-2018, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@class ShortcutView;

@interface PreferencesWindowController : NSWindowController

- (void) selectPane:(NSInteger)tag animated:(BOOL)animated;

- (IBAction) selectPane:(id)sender;
- (IBAction) updatePreferences:(id)sender;

- (IBAction) restoreDefaultColors:(id)sender;

@property (nonatomic, weak) Preferences *preferences;

@property (nonatomic, weak) IBOutlet ShortcutView *captureSelectionShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView *importFromClipboardShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView *showScreenshotsShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView *toggleScreenshotsShortcutView;

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *appearanceItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *keyboardItem;

@property (nonatomic, strong) IBOutlet NSView *generalPane;
@property (nonatomic, strong) IBOutlet NSView *appearancePane;
@property (nonatomic, strong) IBOutlet NSView *keyboardPane;

@property (nonatomic, weak)   IBOutlet NSButton *launchAtLoginButton;

@end
