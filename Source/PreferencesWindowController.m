//  (c) 2011-2018, Ricci Adams.  All rights reserved.


#import "PreferencesWindowController.h"

#import "Preferences.h"
#import "ShortcutView.h"

@interface PreferencesWindowController ()
- (void) _handlePreferencesDidChange:(NSNotification *)note;
@end


@implementation PreferencesWindowController


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

    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}


#pragma mark - Private Methods

- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    [_captureSelectionShortcutView    setShortcut:[preferences captureSelectionShortcut]];
    [_importFromClipboardShortcutView setShortcut:[preferences importFromClipboardShortcut]];
    [_showScreenshotsShortcutView     setShortcut:[preferences showScreenshotsShortcut]];
    [_toggleScreenshotsShortcutView   setShortcut:[preferences toggleScreenshotsShortcut]];
}


#pragma mark - Public Methods

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
        item = _keyboardItem;
        pane = _keyboardPane;
        title = NSLocalizedString(@"Keyboard", nil);

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
    
    newFrame.origin    = windowFrame.origin;
    newFrame.origin.y += (windowFrame.size.height - newFrame.size.height);

    [pane setFrameOrigin:NSZeroPoint];
    
    if (pane == _keyboardPane && ([[Preferences sharedInstance] iconMode] == IconModeInMenuBar)) {
        CGFloat delta = 35;

        [pane setFrameOrigin:NSMakePoint(0, -delta)];
        newFrame.size.height -= delta;
        newFrame.origin.y += delta;
    }


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

    } else if (sender == _importFromClipboardShortcutView) {
        [preferences setImportFromClipboardShortcut:[sender shortcut]];

    } else if (sender == _showScreenshotsShortcutView) {
        [preferences setShowScreenshotsShortcut:[sender shortcut]];

    } else if (sender == _toggleScreenshotsShortcutView) {
        [preferences setToggleScreenshotsShortcut:[sender shortcut]];
    }
}


- (IBAction) restoreDefaultColors:(id)sender
{
    [[Preferences sharedInstance] restoreDefaultColors];
}


@end
