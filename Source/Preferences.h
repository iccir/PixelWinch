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

typedef NS_ENUM(NSInteger, PreferredDisplay) {
    PreferredDisplaySame = 0,
    PreferredDisplayMain = -1
};


@interface Preferences : NSObject

+ (instancetype) sharedInstance;

- (void) restoreDefaultColors;

@property (nonatomic) BOOL pausesDuringCapture;
@property (nonatomic) BOOL usesPoints;

@property (nonatomic) Shortcut *captureSelectionShortcut;
@property (nonatomic) Shortcut *captureWindowShortcut;
@property (nonatomic) Shortcut *showScreenshotsShortcut;

@property (nonatomic) long long preferredDisplay;
@property (nonatomic) NSString *preferredDisplayName;

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
