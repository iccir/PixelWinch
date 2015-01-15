//
//  PreferencesWindowController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShortcutView;

@interface PreferencesWindowController : NSWindowController

- (IBAction) selectPane:(id)sender;
- (IBAction) updatePreferences:(id)sender;

- (IBAction) restoreDefaultColors:(id)sender;

- (IBAction) purchaseFullVersion:(id)sender;
- (IBAction) restorePreviousPurchases:(id)sender;

- (IBAction) updatePreferredDisplay:(id)sender;

@property (nonatomic, weak) Preferences *preferences;

@property (nonatomic, weak) IBOutlet ShortcutView *captureSelectionShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView *showScreenshotsShortcutView;

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *appearanceItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *keyboardItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *purchaseItem;

@property (nonatomic, strong) IBOutlet NSView *generalPane;
@property (nonatomic, strong) IBOutlet NSView *appearancePane;
@property (nonatomic, strong) IBOutlet NSView *keyboardPane;
@property (nonatomic, strong) IBOutlet NSView *purchasePane;

@property (nonatomic, weak)   IBOutlet NSPopUpButton *screenPopUp;

@property (nonatomic, strong) IBOutlet NSView *timedPane;
@property (nonatomic, weak)   IBOutlet NSTextField *timedTitleField;
@property (nonatomic, weak)   IBOutlet NSTextField *timedTextField;
@property (nonatomic, weak)   IBOutlet NSTextField *timedRemainingField;

@end
