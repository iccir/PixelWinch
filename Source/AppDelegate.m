//
//  PixelsAppDelegate.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2011-05-01.
//  Copyright 2011 Stellar Squid, LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "ShortcutManager.h"

#import "CaptureController.h"
#import "PreferencesController.h"
#import "WinchWindowController.h"


@interface AppDelegate () <ShortcutListener>
@end


@implementation AppDelegate {
    NSStatusItem *_statusItem;

    PreferencesController *_preferencesController;
    WinchWindowController *_winchController;
    CaptureController     *_captureController;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) cancelOperation:(id)sender
{
    NSLog(@"CANCEL OP!");
}

- (void) keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
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


- (BOOL) performShortcut:(Shortcut *)shortcut
{
    Preferences *preferences = [Preferences sharedInstance];
    BOOL yn = NO;

    if ([[preferences captureWindowShortcut] isEqual:shortcut]) {
        [self captureWindow:self];
        yn = YES;
    }
    
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


- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:29.0];

    NSImage *image = [NSImage imageNamed:@"status_bar"];
    [image setTemplate:YES];
    [_statusItem setImage:image];
    [_statusItem setHighlightMode:YES];
    
    [_statusItem setMenu:[self statusBarMenu]];
}


- (IBAction) captureSelection:(id)sender
{
    [[self captureController] captureSelection:self];
}


- (IBAction) captureWindow:(id)sender
{
}


- (IBAction) showScreenshots:(id)sender
{
    [[self winchController] showWindow:self];
}


- (IBAction) showPreferences:(id)sender
{
    [[self preferencesController] showWindow:self];
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


- (WinchWindowController *) winchController
{
    @synchronized(self) {
        if (!_winchController) {
            _winchController = [[WinchWindowController alloc] initWithWindowNibName:@"WinchWindow"];
        }
        
        return _winchController;
    }
}


@end
