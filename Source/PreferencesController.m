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

#import "Expiration.h"

@interface PreferencesController ()
- (void) _handlePreferencesDidChange:(NSNotification *)note;
@end


@implementation PreferencesController


- (id) initWithWindow:(NSWindow *)window
{
    if ((self = [super initWithWindow:window])) {
        [self setPreferences:[Preferences sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleApplicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
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

    [self _setupScreenMenu];

    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}


#pragma mark - Private Methods

- (void) _setupScreenMenu
{
    NSScreen *mainScreen = [[NSScreen screens] firstObject];
    BOOL foundPreferred  = NO;
    __block BOOL addedSeparator = NO;

    NSMenu *menu = [_screenPopUp menu];
    [menu removeAllItems];
    [menu setAutoenablesItems:NO];
    
    NSMenuItem *sameItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Same Display", nil) action:nil keyEquivalent:@""];
    [sameItem setTag:PreferredDisplaySame];
    [menu addItem:sameItem];

    NSMenuItem *mainItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Main Display", nil) action:nil keyEquivalent:@""];
    [mainItem setTag:PreferredDisplayMain];
    [menu addItem:mainItem];
    
    long long preferredDisplay = [[Preferences sharedInstance] preferredDisplay];
    
    void (^add)(long long, NSString *) = ^(long long tag, NSString *name) {
        if (!addedSeparator) {
            [menu addItem:[NSMenuItem separatorItem]];
            addedSeparator = YES;
            
            NSFont *groupFont = [NSFont boldSystemFontOfSize:12];

            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Other Displays", nil) attributes:@{
                NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.66 alpha:1.0],
                NSFontAttributeName: groupFont
            }];

            NSMenuItem *otherItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
            [otherItem setAttributedTitle:attributedTitle];
            [menu addItem:otherItem];

            [otherItem setEnabled:NO];

        }

        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
        [item setTag:tag];
        [menu addItem:item];
    };
    
    for (NSScreen *screen in [NSScreen screens]) {
        if (screen == mainScreen) {
            continue;
        }
        
        long long screenID = [screen winch_CGDirectDisplayID];

        if (screenID == preferredDisplay) {
            foundPreferred = YES;
        }


        add(screenID, [screen winch_name]);
    }

    if (!foundPreferred &&
        (preferredDisplay != PreferredDisplaySame) &&
        (preferredDisplay != PreferredDisplayMain))
    {
        add(preferredDisplay, [[Preferences sharedInstance] preferredDisplayName]);
    }

    [_screenPopUp selectItemWithTag:[[Preferences sharedInstance] preferredDisplay]];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    Preferences *preferences = [Preferences sharedInstance];

    [_captureSelectionShortcutView setShortcut:[preferences captureSelectionShortcut]];
    [_showScreenshotsShortcutView  setShortcut:[preferences showScreenshotsShortcut]];
}


- (void) _handleApplicationDidChangeScreenParameters:(NSNotification *)note
{
    [self _setupScreenMenu];
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

    } else if (tag == 10) {
        title = NSLocalizedString(@"Purchase", nil);
        item = _purchaseItem;

#if ENABLE_APP_STORE
        pane = _purchasePane;
#else
        __block long long expiration = kExpirationLong;

        [_timedRemainingField setStringValue:@""];
        
        ^{
            if (CFAbsoluteTimeGetCurrent() > expiration) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
                    int *zero = (int *)(long)(rand() >> 31);
                    *zero = 0;
                });

            } else {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:expiration];

                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateStyle:NSDateFormatterFullStyle];
                [formatter setTimeStyle:NSDateFormatterNoStyle];
                
                [_timedRemainingField setStringValue:[formatter stringFromDate:date]];
            }
        }();

        pane = _timedPane;
#endif

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
#if ENABLE_APP_STORE

#endif
}


- (IBAction) restorePreviousPurchases:(id)sender
{
#if ENABLE_APP_STORE

#endif
}


- (IBAction) updatePreferredDisplay:(id)sender
{
    NSMenuItem *selectedItem = [_screenPopUp selectedItem];

    [[Preferences sharedInstance] setPreferredDisplay:[selectedItem tag]];
    [[Preferences sharedInstance] setPreferredDisplayName:[selectedItem title]];
}


- (IBAction) visitWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchWebsiteURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


@end
