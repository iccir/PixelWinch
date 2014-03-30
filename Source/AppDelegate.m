//
//  PixelsAppDelegate.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-09-27.
//  Copyright 2013 Ricci Adams. All rights reserved.
//

#import "AppDelegate.h"

#import "ShortcutManager.h"

#import "AboutWindowController.h"
#import "CanvasController.h"
#import "CaptureController.h"
#import "PreferencesController.h"

#import "Library.h"
#import "LibraryItem.h"
#import "DebugControlsController.h"
#import "TutorialWindowController.h"

#import <HockeySDK/HockeySDK.h>
#import <HockeySDK/BITHockeyManager.h>

#if ENABLE_APP_STORE
#import "ReceiptValidation_A.h"
#else
#import "Expiration.h"
#endif


#define SHOW_DEBUG_CONTROLS 0


#define sCheckAndProtect _
static inline __attribute__((always_inline)) void sCheckAndProtect()
{
#if ENABLE_APP_STORE
    if (![[PurchaseManager sharedInstance] doesReceiptExist]) {
        exit(173);
    }
#else
    ^{
        NSString *message = NSLocalizedString(@"Version Expired", nil);
        NSString *text    = NSLocalizedString(@"This version of Pixel Winch has expired.  A newer version may be available on the Pixel Winch website.", nil);
        NSString *quit    = NSLocalizedString(@"Quit",    nil);
        NSString *visit   = NSLocalizedString(@"Visit Website",    nil);
        
        NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:quit alternateButton:visit otherButton:nil informativeTextWithFormat:@"%@", text];

        if (CFAbsoluteTimeGetCurrent() > kExpirationDouble) {
            if ([alert runModal] == 0) {
                NSURL *url = [NSURL URLWithString:GetPixelWinchWebsiteURLString()];
                [[NSWorkspace sharedWorkspace] openURL:url];
            }
            
            [NSApp terminate:nil];
            exit(0);

            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
                int *zero = (int *)(long)(rand() >> 31);
                *zero = 0;
            });
        }
    }();
#endif
}


@interface AppDelegate () <NSMenuDelegate, ShortcutListener, BITHockeyManagerDelegate>
@end


@implementation AppDelegate {
    NSStatusItem *_statusItem;
    NSTimer      *_periodicTimer;

    AboutWindowController    *_aboutController;
    PreferencesController    *_preferencesController;
    CanvasController         *_canvasController;
    CaptureController        *_captureController;
    TutorialWindowController *_tutorialWindowController;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    [self _updateShortcuts];
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
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:33.0];

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
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"<redacted>" companyName:@"Ricci Adams" delegate:self];
        [[BITHockeyManager sharedHockeyManager] startManager];
    }
    
#if 0
#if !ENABLE_APP_STORE
    NSString *sparklePath = [[NSBundle mainBundle] resourcePath];
    sparklePath = [sparklePath stringByDeletingLastPathComponent];
    sparklePath = [sparklePath stringByAppendingPathComponent:@"Frameworks"];
    sparklePath = [sparklePath stringByAppendingPathComponent:@"Sparkle.framework"];

    [[NSBundle bundleWithPath:sparklePath] load];
    
    SUUpdater *updater = [NSClassFromString(@"SUUpdater") updaterForBundle:[NSBundle mainBundle]];
    [updater setFeedURL:[NSURL URLWithString:@"<redacted>"]];
    [updater setAutomaticallyChecksForUpdates:YES];
    [updater checkForUpdatesInBackground];
#endif
#endif
}


- (void) showMainApplicationWindowForCrashManager:(BITCrashManager *)crashManager
{
    NSImage *image = [NSImage imageNamed:@"status_bar"];
    [image setTemplate:YES];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"did-show-arrow"]) {
        _tutorialWindowController = [[TutorialWindowController alloc] init];
        [_tutorialWindowController orderInWithStatusItem:_statusItem];
    }
    
    [[self statusBarMenu] setDelegate:self];

    [_statusItem setImage:image];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:[self statusBarMenu]];
    

#ifdef DEBUG
#if SHOW_DEBUG_CONTROLS
    DebugControlsController *controlsController = [[DebugControlsController alloc] init];
    [controlsController showWindow:self];
    CFBridgingRetain(controlsController);
#endif
#endif

    [self _updateShortcuts];
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
    [[self captureController] captureSelection:self];
}


- (IBAction) showScreenshots:(id)sender
{
    [[self canvasController] toggleVisibility];
}


- (IBAction) showPreferences:(id)sender
{
    [[self preferencesController] showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (IBAction) showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];

    if (!_aboutController) {
        _aboutController = [[AboutWindowController alloc] initWithWindowNibName:@"About"];
    }
    
    [[_aboutController window] center];
    [[_aboutController window] makeKeyAndOrderFront:self];
}


- (IBAction) provideFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchFeedbackURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) quit:(id)sender
{
    [[self canvasController] saveCurrentLibraryItem];
    [NSApp terminate:self];
}


- (PreferencesController *) preferencesController
{
    @synchronized(self) {
        if (!_preferencesController) {
            _preferencesController = [[PreferencesController alloc] init];
        }
        
        return _preferencesController;
    }
}


- (CaptureController *) captureController
{
    @synchronized(self) {
        if (!_captureController) {
            _captureController = [[CaptureController alloc] init];
        }
        
        return _captureController;
    }
}


- (CanvasController *) canvasController
{
    @synchronized(self) {
        if (!_canvasController) {
            _canvasController = [[CanvasController alloc] initWithWindowNibName:@"CanvasWindow"];
        }
        
        return _canvasController;
    }
}


@end
