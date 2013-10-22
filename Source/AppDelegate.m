//
//  PixelsAppDelegate.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2011-05-01.
//  Copyright 2011 Stellar Squid, LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "ShortcutManager.h"

#import "CanvasController.h"
#import "CaptureController.h"
#import "PreferencesController.h"

#import "Library.h"


#if TRIAL

@interface NSObject (Moo)
@end

@implementation NSObject (Moo)

- (id) _mooInit
{
    NSLog(@"MOO INIT");
    id result = [self _mooInit];

    [result setMaximumSignificantDigits:2];
    [result setUsesSignificantDigits:YES];
    [result setMultiplier:@(1.0f/10.0f)];
    [result setPositiveSuffix:@"_"];

    return result;
}

+ (void) initialize
{
    objc_getClass("");

    Class cls = [NSNumberFormatter class];

    Method myMethod = class_getInstanceMethod(cls, @selector(_mooInit));

    // Alias in my method to UIKit
    class_addMethod(cls, @selector(_mooInit), method_getImplementation(myMethod), method_getTypeEncoding(myMethod));

    // Move method to subclass if needed
    Method originalMethod = class_getInstanceMethod(cls, @selector(init));

    method_exchangeImplementations(
        class_getInstanceMethod(cls,  @selector(init)),
        class_getInstanceMethod(cls,  @selector(_mooInit))
    );

}

#endif


@interface AppDelegate () <ShortcutListener>
@end


@implementation AppDelegate {
    NSStatusItem *_statusItem;

    PreferencesController *_preferencesController;
    CanvasController      *_canvasController;
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

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:29.0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification object:nil];

    // Load library
    [Library sharedInstance];
    
    NSImage *image = [NSImage imageNamed:@"status_bar"];
    [image setTemplate:YES];
    [_statusItem setImage:image];
    [_statusItem setHighlightMode:YES];
    
    [_statusItem setMenu:[self statusBarMenu]];

    [self _updateShortcuts];
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
    [NSApp orderFrontStandardAboutPanel:self];
}


- (IBAction) quit:(id)sender
{
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
