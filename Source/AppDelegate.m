//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "AppDelegate.h"

#import <ServiceManagement/ServiceManagement.h>

#import "ShortcutManager.h"

#import "AboutWindowController.h"
#import "CanvasWindowController.h"
#import "PreferencesWindowController.h"
#import "TutorialWindowController.h"

#import "CaptureManager.h"

#import "Library.h"
#import "LibraryItem.h"


@interface AppDelegate () <NSMenuDelegate, ShortcutListener>
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

    } else if ([item action] == @selector(importImageFromPasteboard:)) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        
        return [pboard canReadObjectForClasses:@[ [NSImage class] ] options:nil];
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

    } else if ([[preferences importFromClipboardShortcut] isEqual:shortcut]) {
        yn = [[self canvasWindowController] importImagesWithPasteboard:[NSPasteboard generalPasteboard]];
    }
    
    if ([[preferences toggleScreenshotsShortcut] isEqual:shortcut]) {
        [[self canvasWindowController] performToggleWindowShortcut];
        yn = YES;
    
    } else if ([[preferences showScreenshotsShortcut] isEqual:shortcut]) {
        [[self canvasWindowController] activateAndShowWindow];
        yn = YES;
    }

    return yn;
}


- (void) _updateLaunchHelper
{
    BOOL launchAtLogin = [[Preferences sharedInstance] launchAtLogin];

    CFStringRef bundleID = CFBridgingRetain([[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".Launcher"]);

    if (bundleID) {
        if (launchAtLogin) {
            if (!SMLoginItemSetEnabled(bundleID, YES)) {
                NSString *errorMessage = NSLocalizedString(@"Couldn't add Pixel Winch to Login Items list.", nil);

                NSAlert *alert = [[NSAlert alloc] init];
                [alert setInformativeText:errorMessage];
                [alert runModal];
                
                [[Preferences sharedInstance] setLaunchAtLogin:NO];
            }

        } else {
            SMLoginItemSetEnabled(bundleID, NO);
        }

        CFRelease(bundleID);
    }
}


- (void) _updateDockAndMenuBar
{
    IconMode iconMode = [[Preferences sharedInstance] iconMode];

    NSMenuItem *quitMenuItem = [self quitMenuItem];

    [quitMenuItem setKeyEquivalent:@""];
    [quitMenuItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];

    if (iconMode == IconModeInDock || iconMode == IconModeInBoth) {
        if ([[Preferences sharedInstance] allowsQuit]) {
            [quitMenuItem setKeyEquivalent:@"q"];
            [quitMenuItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
        }
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
    
    if (iconMode == IconModeInMenuBar) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    } else if (iconMode == IconModeInDock) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    }
}


- (void) _updateShortcuts
{
    Preferences    *preferences = [Preferences sharedInstance];
    NSMutableArray *shortcuts   = [NSMutableArray array];

    if ([preferences captureSelectionShortcut]) {
        [shortcuts addObject:[preferences captureSelectionShortcut]];
    }

    if ([preferences importFromClipboardShortcut]) {
        [shortcuts addObject:[preferences importFromClipboardShortcut]];
    }

    if ([preferences showScreenshotsShortcut]) {
        [shortcuts addObject:[preferences showScreenshotsShortcut]];
    }

    if ([preferences toggleScreenshotsShortcut]) {
        [shortcuts addObject:[preferences toggleScreenshotsShortcut]];
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
}


- (void) applicationWillTerminate:(NSNotification *)notification
{
    [self _cleanupLibrary:YES];
}


- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows
{
    [[self canvasWindowController] activateAndShowWindow];
    return YES;
}


- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
#if ENABLE_BETA
    ^{
        NSString *message = NSLocalizedString(@"Beta Expired", nil);
        NSString *text    = NSLocalizedString(@"This version of Pixel Winch has expired.  Please contact me if you need a new build.", nil);
        NSString *quit    = NSLocalizedString(@"Quit",    nil);
        NSString *visit   = NSLocalizedString(@"Contact Me",    nil);
        
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setMessageText:message];
        [alert setInformativeText:text];
        [alert addButtonWithTitle:quit];
        [alert addButtonWithTitle:visit];

        if (CFAbsoluteTimeGetCurrent() > kExpirationDouble) {
            if ([alert runModal] == NSAlertSecondButtonReturn) {
                NSURL *url = [NSURL URLWithString:WinchFeedbackURLString];
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

    [self _updateShortcuts];
    [self _updateDockAndMenuBar];
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
    [openPanel setAllowedFileTypes:[NSImage imageTypes]];

    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *url = [openPanel URL];
            [[self canvasWindowController] importFilesAtPaths:@[ [url path] ]];
        }
    }];
}


- (IBAction) importImageFromPasteboard:(id)sender
{
    [[self canvasWindowController] importImagesWithPasteboard:[NSPasteboard generalPasteboard]];
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

    NSURL *url = [NSURL URLWithString:WinchFeedbackURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) visitWebsite:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    NSURL *url = [NSURL URLWithString:WinchWebsiteURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewGuide:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    NSURL *url = [NSURL URLWithString:WinchGuideURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewOnAppStore:(id)sender
{
    [[self canvasWindowController] hideIfOverlay];

    NSURL *url = [NSURL URLWithString:WinchAppStoreURLString];
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
