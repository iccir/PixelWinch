//
//  PixelsAppDelegate.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-09-27.
//  Copyright 2013 Ricci Adams. All rights reserved.
//

#import "AppDelegate.h"

#import <HockeySDK/HockeySDK.h>
#import <HockeySDK/BITHockeyManager.h>
#import <ServiceManagement/ServiceManagement.h>

#import "ShortcutManager.h"

#import "AboutWindowController.h"
#import "CanvasWindowController.h"
#import "PreferencesWindowController.h"

#import "CaptureManager.h"

#import "Library.h"
#import "LibraryItem.h"
#import "TutorialWindowController.h"

#import "Beacon.h"

objc_arc_weakLock __arc_weak_lock = {
    0,
    0,
    0,
    0
};


@interface AppDelegate () <NSMenuDelegate, ShortcutListener, BITHockeyManagerDelegate>
@end


@implementation AppDelegate {
    NSStatusItem *_statusItem;
    NSTimer      *_periodicTimer;

    AboutWindowController       *_aboutWindowController;
    PreferencesWindowController *_preferencesWindowController;
    CanvasWindowController      *_canvasWindowController;
    TutorialWindowController    *_tutorialWindowController;

    CaptureManager *_captureManager;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    [self _updateShortcuts];
    [self _updateLaunchHelper];
    [self _updateDockAndMenuBar];
}


- (BOOL) validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
    if ([item action] == @selector(showScreenshots:)) {
        if ([(id)item isKindOfClass:[NSMenuItem class]]) {
            NSMenuItem *menuItem = (NSMenuItem *)item;

            if ([[self canvasWindowController] isWindowVisible]) {
                [menuItem setTitle:NSLocalizedString(@"Hide Screenshots", nil)];
            } else {
                [menuItem setTitle:NSLocalizedString(@"Show Screenshots\\U2026", nil)];
            }
        }
    
        return [[[Library sharedInstance] items] count] > 0;
    }

    return YES;
}


- (BOOL) performShortcut:(Shortcut *)shortcut
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL yn = NO;
    
    if ([[preferences captureSelectionShortcut] isEqual:shortcut]) {
        [self captureSelection:self];
        yn = YES;
    }
    
    if ([[preferences showScreenshotsShortcut] isEqual:shortcut]) {
        [self showScreenshots:self];
        yn = YES;
    }

    return yn;
}


- (void) _updateLaunchHelper
{
    BOOL launchAtLogin = [[Preferences sharedInstance] launchAtLogin];

    CFStringRef bundleID = CFSTR("com.pixelwinch.LaunchPixelWinch");

    if (launchAtLogin) {
        if (!SMLoginItemSetEnabled(bundleID, YES)) {
            NSString *errorMessage = NSLocalizedString(@"Couldn't add Pixel Winch to Login Items list.", nil);

            NSAlert *alert = [[NSAlert alloc] init];
            [alert setInformativeText:errorMessage];
            [alert runModal];
            
            [[Preferences sharedInstance] setLaunchAtLogin:NO];
        }

    } else {
        SMLoginItemSetEnabled (bundleID, NO);
    }
}


- (void) _updateDockAndMenuBar
{
    ProtectEntry();

    IconMode iconMode = [[Preferences sharedInstance] iconMode];

    NSApplicationActivationPolicy currentActivationPolicy = [NSApp activationPolicy];
    NSMenuItem *quitMenuItem = [self quitMenuItem];

    [quitMenuItem setKeyEquivalent:@""];
    [quitMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];

    if (iconMode == IconModeInDock || iconMode == IconModeInBoth) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        if ([[Preferences sharedInstance] allowsQuit]) {
            [quitMenuItem setKeyEquivalent:@"q"];
            [quitMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
        }

    // We are moving from NSApplicationActivationPolicyRegular -> NSApplicationActivationPolicyAccessory
    // This will hide windows, so do an elaborate workaround
    } else if (currentActivationPolicy != NSApplicationActivationPolicyAccessory) {
        BOOL wasActive = [NSApp isActive];
        
        NSMutableArray *visibleWindows = [NSMutableArray array];
        NSWindow *keyWindow = nil;

        for (NSWindow *window in [NSApp windows]) {
            if ([window isVisible]) {
                [visibleWindows addObject:window];
            }
            if ([window isKeyWindow]) {
                keyWindow = window;
            }
        }
        
        NSDisableScreenUpdates();
        
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (wasActive) [NSApp activateIgnoringOtherApps:YES];

            for (NSWindow *window in visibleWindows) {
                [window orderFront:self];
            }

            [keyWindow makeKeyAndOrderFront:self];

            NSEnableScreenUpdates();
        });
    }

    if (iconMode == IconModeInMenuBar || iconMode == IconModeInBoth) {
        if (!_statusItem) {
            _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:33.0];

            NSImage *image = [NSImage imageNamed:@"StatusBarIcon"];
            [image setTemplate:YES];
            
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"did-show-arrow"]) {
                _tutorialWindowController = [[TutorialWindowController alloc] init];
                [_tutorialWindowController orderInWithStatusItem:_statusItem];
            }
            
            [[self statusBarMenu] setDelegate:self];

            [_statusItem setImage:image];
            [_statusItem setHighlightMode:YES];
            [_statusItem setMenu:[self statusBarMenu]];
        }
    } else {
        if (_statusItem) {
            [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
            _statusItem = nil;
        }
    }

    ProtectExit();
}


- (void) _updateShortcuts
{
    ProtectEntry();

    Preferences    *preferences = [Preferences sharedInstance];
    NSMutableArray *shortcuts   = [NSMutableArray array];

    if ([preferences captureSelectionShortcut]) {
        [shortcuts addObject:[preferences captureSelectionShortcut]];
    }

    if ([preferences captureWindowShortcut]) {
        [shortcuts addObject:[preferences captureWindowShortcut]];
    }

    if ([preferences showScreenshotsShortcut]) {
        [shortcuts addObject:[preferences showScreenshotsShortcut]];
    }

    if ([shortcuts count] || [ShortcutManager hasSharedInstance]) {
        [[ShortcutManager sharedInstance] addListener:self];
        [[ShortcutManager sharedInstance] setShortcuts:shortcuts];
    }

    ProtectExit();
}


- (void) _cleanupLibrary:(BOOL)isTerminating
{
    ScreenshotExpiration screenshotExpiration = [[Preferences sharedInstance] screenshotExpiration];
    if (screenshotExpiration == 0) {
        return;
    }

    Library *library = [Library sharedInstance];
    NSMutableArray *items = [[library items] mutableCopy];

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    if (screenshotExpiration > 0) {
        for (LibraryItem *item in items) {
            NSInteger daysOld = (now - [[item date] timeIntervalSinceReferenceDate]) / (60.0 * 60.0 * 24.0);

            if (daysOld >= screenshotExpiration) {
                [library removeItem:item];
            }
        }
    
    } else if (screenshotExpiration == ScreenshotExpirationOnQuit) {
        if (isTerminating) {
            for (LibraryItem *item in items) {
                [library removeItem:item];
            }
        }
        
        return;
    }
}


- (void) _handlePeriodicUpdate:(NSTimer *)timer
{
    ProtectEntry();
    [self _cleanupLibrary:NO];
    ProtectExit();
}


- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
}


- (void) applicationWillTerminate:(NSNotification *)notification
{
    [self _cleanupLibrary:YES];
}


- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows
{
    if (!hasVisibleWindows) {
        [[self canvasWindowController] toggleVisibility];
    }

    return YES;
}


- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    ProtectEntry();

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];

    // Load library
    [Library sharedInstance];

    _periodicTimer = [[NSTimer alloc] initWithFireDate: [NSDate date]
                                              interval: 60 * 60 * 3
                                                target: self
                                              selector: @selector(_handlePeriodicUpdate:)
                                              userInfo: nil
                                               repeats: YES];

    [[NSRunLoop currentRunLoop] addTimer:_periodicTimer forMode:NSRunLoopCommonModes];


    if (IsInDebugger()) {
        [self showMainApplicationWindowForCrashManager:nil];

    } else {
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"<redacted>" delegate:self];
        [[BITHockeyManager sharedHockeyManager] setDisableFeedbackManager:YES];
        [[BITHockeyManager sharedHockeyManager] startManager];
    }

    ProtectExit();
}


- (BOOL) application:(NSApplication *)sender openFile:(NSString *)filename
{
    if (!filename) return NO;
    return [[self canvasWindowController] importFilesAtPaths:@[ filename ]];
}


- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    ProtectEntry();
    [[self canvasWindowController] importFilesAtPaths:filenames];
    ProtectExit();
}


- (void) showMainApplicationWindowForCrashManager:(BITCrashManager *)crashManager
{
    [self _updateShortcuts];
    [self _updateDockAndMenuBar];
}

- (void) menuWillOpen:(NSMenu *)menu
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"did-show-arrow"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (_tutorialWindowController) {
        [_tutorialWindowController orderOut];
        _tutorialWindowController = nil;
    }
}


- (IBAction) captureSelection:(id)sender
{
    [[self captureManager] captureSelection:self];
}


- (IBAction) importImage:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setTitle:NSLocalizedString(@"Import Image", nil)];
    [openPanel setAllowedFileTypes:[NSImage imageFileTypes]];

    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSURL *url = [openPanel URL];
            [[self canvasWindowController] importFilesAtPaths:@[ [url path] ]];
        }
    }];
}


- (IBAction) showScreenshots:(id)sender
{
    [[self canvasWindowController] toggleVisibility];
}


- (IBAction) showPreferences:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    [[self preferencesWindowController] showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (IBAction) showPurchasePane:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    [[self preferencesWindowController] showWindow:self];
    [[self preferencesWindowController] selectPane:3 animated:NO];

    [NSApp activateIgnoringOtherApps:YES];
}


- (IBAction) showAbout:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    [NSApp activateIgnoringOtherApps:YES];

    if (!_aboutWindowController) {
        _aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"About"];
    }
    
    [[_aboutWindowController window] center];
    [[_aboutWindowController window] makeKeyAndOrderFront:self];
}


- (IBAction) provideFeedback:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    NSURL *url = [NSURL URLWithString:GetPixelWinchFeedbackURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) visitWebsite:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    NSURL *url = [NSURL URLWithString:GetPixelWinchWebsiteURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewOnAppStore:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    NSURL *url = [NSURL URLWithString:GetPixelWinchOnAppStoreURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) quit:(id)sender
{
    [[self canvasWindowController] saveCurrentLibraryItem];
    [NSApp terminate:self];
}


- (PreferencesWindowController *) preferencesWindowController
{
    @synchronized(self) {
        if (!_preferencesWindowController) {
            _preferencesWindowController = [[PreferencesWindowController alloc] init];
        }
        
        return _preferencesWindowController;
    }
}


- (CaptureManager *) captureManager
{
    @synchronized(self) {
        if (!_captureManager) {
            _captureManager = [[CaptureManager alloc] init];
        }
        
        return _captureManager;
    }
}


- (CanvasWindowController *) canvasWindowController
{
    @synchronized(self) {
        if (!_canvasWindowController) {
            _canvasWindowController = [[CanvasWindowController alloc] initWithWindowNibName:@"CanvasWindow"];
        }
        
        return _canvasWindowController;
    }
}


@end
