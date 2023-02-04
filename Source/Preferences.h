//
//  Preferences.h
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PreferencesDidChangeNotification;

@class Shortcut;

typedef NS_ENUM(NSInteger, ScreenshotExpiration) {
    ScreenshotExpirationNever = 0,
    ScreenshotExpirationOnQuit = -1
};

typedef NS_ENUM(NSInteger, CloseScreenshotsKey) {
    CloseScreenshotsKeyCommandW  = 0,
    CloseScreenshotsKeyEscape    = 1,
    CloseScreenshotsKeyBoth      = 2
};

typedef NS_ENUM(NSInteger, CanvasAppearance) {
    CanvasAppearanceSystemDefault = 0,
    CanvasAppearanceLightMode     = 1,
    CanvasAppearanceDarkMode      = 2
};

typedef NS_ENUM(NSInteger, IconMode) {
    IconModeInMenuBar = 0,
    IconModeInDock    = 1,
    IconModeInBoth    = 2
};


@interface Preferences : NSObject

+ (void) registerDefaults;

+ (instancetype) sharedInstance;

- (void) restoreDefaultColors;

@property (nonatomic) CanvasAppearance canvasAppearance;
@property (nonatomic) IconMode iconMode;

@property (nonatomic) BOOL allowsQuit;

@property (nonatomic) NSInteger scaleMode;
@property (nonatomic) NSString *customScaleMultiplier;

@property (nonatomic) Shortcut *captureSelectionShortcut;
@property (nonatomic) Shortcut *importFromClipboardShortcut;
@property (nonatomic) Shortcut *showScreenshotsShortcut;
@property (nonatomic) Shortcut *toggleScreenshotsShortcut;

@property (nonatomic) NSInteger closeScreenshotsKey;

@property (nonatomic) NSInteger screenshotExpiration;

@property (nonatomic) NSInteger measurementCopyType;

@property (nonatomic) NSColor *placedGuideColor;
@property (nonatomic) NSColor *activeGuideColor;

@property (nonatomic) NSColor *placedGrappleColor;
@property (nonatomic) NSColor *previewGrappleColor;
@property (nonatomic) NSColor *activeGrappleColor;

@property (nonatomic) NSColor *placedRectangleFillColor;
@property (nonatomic) NSColor *placedRectangleBorderColor;

@end
