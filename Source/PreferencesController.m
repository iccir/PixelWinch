//
//  PreferencesController.h
//  ColorMeter
//
//  Created by Ricci Adams on 2011-07-28.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "PreferencesController.h"

#import "Preferences.h"
#import "ShortcutView.h"

@interface PreferencesController ()
- (void) _handlePreferencesDidChange:(NSNotification *)note;
@end


@implementation PreferencesController


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        [self setPreferences:[Preferences sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
    }
    
    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString *) windowNibName
{
    return @"Preferences";
}


- (void ) windowDidLoad
{
    [self _handlePreferencesDidChange:nil];
    [self selectPane:0 animated:NO];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    [_captureSelectionShortcutView setShortcut:[preferences captureSelectionShortcut]];
    [_showScreenshotsShortcutView  setShortcut:[preferences showScreenshotsShortcut]];
}


- (void) selectPane:(NSInteger)tag animated:(BOOL)animated
{
    NSToolbarItem *item;
    NSView *pane;
    NSString *title;

    if (tag == 1) {
        item = _appearanceItem;
        pane = _appearancePane;
        title = NSLocalizedString(@"Conversion", nil);

    } else if (tag == 2) {
        item = _purchaseItem;
        pane = _purchasePane;
        title = NSLocalizedString(@"Purchase", nil);

    } else {
        item = _generalItem;
        pane = _generalPane;
        title = NSLocalizedString(@"General", nil);
    }
    
    [_toolbar setSelectedItemIdentifier:[item itemIdentifier]];
    
    NSWindow *window = [self window];
    NSView *contentView = [window contentView];
    for (NSView *view in [contentView subviews]) {
        [view removeFromSuperview];
    }

    NSRect paneFrame = [pane frame];
    NSRect windowFrame = [window frame];
    NSRect newFrame = [window frameRectForContentRect:paneFrame];
    
    newFrame.origin = windowFrame.origin;
    newFrame.origin.y += (windowFrame.size.height - newFrame.size.height);

    [window setFrame:newFrame display:YES animate:animated];
    [window setTitle:title];

    [contentView addSubview:pane];
}


- (IBAction) selectPane:(id)sender
{
    [self selectPane:[sender tag] animated:YES];
}


- (IBAction) updatePreferences:(id)sender
{
    Preferences *preferences = [Preferences sharedInstance];

    if (sender == _captureSelectionShortcutView) {
        [preferences setCaptureSelectionShortcut:[sender shortcut]];
        
    } else if (sender == _showScreenshotsShortcutView) {
        [preferences setShowScreenshotsShortcut:[sender shortcut]];
    }
}


- (IBAction) restoreDefaultColors:(id)sender
{
    [[Preferences sharedInstance] restoreDefaultColors];
}


- (IBAction) purchaseFullVersion:(id)sender
{

}


- (IBAction) restorePreviousPurchases:(id)sender
{

}


@end
