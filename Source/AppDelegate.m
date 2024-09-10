//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "AppDelegate.h"

#import <ServiceManagement/ServiceManagement.h>

#import "ShortcutManager.h"

#import "AboutWindowController.h"
#import "CanvasWindowController.h"
#import "PreferencesWindowController.h"
#import "MigrationWindowController.h"

#import "CaptureManager.h"

#import "Library.h"
#import "LibraryItem.h"
#import "Migration.h"


@interface AppDelegate () <NSMenuDelegate, ShortcutListener>
@end


@implementation AppDelegate {
    NSStatusItem *_statusItem;
    NSTimer      *_periodicTimer;

    AboutWindowController       *_aboutWindowController;
    PreferencesWindowController *_preferencesWindowController;
    CanvasWindowController      *_canvasWindowController;

    CaptureManager *_captureManager;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    [self _updateShortcuts];
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
               
            [[self statusBarMenu] setDelegate:self];

            [[_statusItem button] setImage:image];
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
    [Preferences registerDefaults];

    BOOL didMigrate = NO;

    if ([Migration needsMigration]) {
        MigrationWindowController *controller = [[MigrationWindowController alloc] initWithWindowNibName:@"MigrationWindow"];

        NSModalResponse response = [NSApp runModalForWindow:[controller window]];
        [[controller window] orderOut:self];
        
        [controller dismissController:self];
        
        if (response == NSModalResponseOK) {
            [Migration migrate];
            didMigrate = YES;
        }
    }
    
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
    
    if (didMigrate) {
        [[self canvasWindowController] toggleVisibility];
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


- (IBAction) captureSelection:(id)sender
{
    [[self captureManager] captureSelection:self];
}


- (IBAction) importImage:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];

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
    NSURL *url = [NSURL URLWithString:WinchFeedbackURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) visitWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchWebsiteURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewGuide:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchGuideURLString];
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
            [_canvasWindowController loadWindow];
        }
        
        return _canvasWindowController;
    }
}


@end
