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

#import "Updater.h"



#if ENABLE_APP_STORE
#import "ReceiptValidation_A.h"
#else
#import "Expiration.h"
#endif


#define sCheckAndProtect _
static inline __attribute__((always_inline)) void sCheckAndProtect()
{
#ifndef ENABLE_APP_STORE
    ^{
        NSString *message = NSLocalizedString(@"Version Expired", nil);
        NSString *text    = NSLocalizedString(@"This version of Pixel Winch has expired.  A newer version may be available on the Pixel Winch website.", nil);
        NSString *quit    = NSLocalizedString(@"Quit",    nil);
        NSString *visit   = NSLocalizedString(@"Visit Website",    nil);
        
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setMessageText:message];
        [alert setInformativeText:text];
        [alert addButtonWithTitle:quit];
        [alert addButtonWithTitle:visit];

        if (CFAbsoluteTimeGetCurrent() > kExpirationDouble) {
            if ([alert runModal] == NSAlertSecondButtonReturn) {
                NSURL *url = [NSURL URLWithString:GetPixelWinchWebsiteURLString()];
                [[NSWorkspace sharedWorkspace] openURL:url];
            }
            
            [NSApp terminate:nil];
            exit(0);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"

            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
                int *zero = (int *)(long)(rand() >> 31);
                *zero = 0;
            });

#pragma clang diagnostic pop

        }
    }();
#endif
}


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
    IconMode iconMode = [[Preferences sharedInstance] iconMode];
    
    [NSApp setMainMenu:nil];
    
    if (iconMode == IconModeInDock || iconMode == IconModeInBoth) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    } else {
        BOOL wasActive = [NSApp isActive];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        if (wasActive) [NSApp activateIgnoringOtherApps:YES];
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
}


- (void) _updateShortcuts
{
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
    [self _cleanupLibrary:NO];
}


- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
    sCheckAndProtect();
}


- (void) applicationWillTerminate:(NSNotification *)notification
{
    [self _cleanupLibrary:YES];
}


- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
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
}


- (BOOL) application:(NSApplication *)sender openFile:(NSString *)filename
{
    if (!filename) return NO;
    return [[self canvasWindowController] importFilesAtPaths:@[ filename ]];
}


- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    [[self canvasWindowController] importFilesAtPaths:filenames];
}


- (void) showMainApplicationWindowForCrashManager:(BITCrashManager *)crashManager
{
    [self _updateShortcuts];
    [self _updateDockAndMenuBar];

#ifndef DEBUG
#if !ENABLE_APP_STORE
    [[Updater sharedInstance] checkForUpdatesInBackground];
#endif
#endif
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


- (IBAction) showScreenshots:(id)sender
{
    [[self canvasWindowController] toggleVisibility];
}


- (IBAction) showPreferences:(id)sender
{
    [[self preferencesWindowController] showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (IBAction) showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];

    if (!_aboutWindowController) {
        _aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"About"];
    }
    
    [[_aboutWindowController window] center];
    [[_aboutWindowController window] makeKeyAndOrderFront:self];
}


- (IBAction) provideFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchFeedbackURLString()];
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
