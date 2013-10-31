//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShortcutView;

@interface PreferencesController : NSWindowController

- (IBAction) selectPane:(id)sender;
- (IBAction) updatePreferences:(id)sender;

@property (nonatomic, weak) Preferences *preferences;

@property (nonatomic, weak) IBOutlet ShortcutView *captureSelectionShortcutView;
@property (nonatomic, weak) IBOutlet ShortcutView *showScreenshotsShortcutView;

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, weak) IBOutlet NSToolbarItem *appearanceItem;

@property (nonatomic, strong) IBOutlet NSView *generalPane;
@property (nonatomic, strong) IBOutlet NSView *appearancePane;


@end
