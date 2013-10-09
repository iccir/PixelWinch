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

@interface Preferences : NSObject

+ (id) sharedInstance;

@property BOOL pausesDuringCapture;
@property BOOL usesPoints;

@property Shortcut *captureSelectionShortcut;
@property Shortcut *captureWindowShortcut;
@property Shortcut *showScreenshotsShortcut;

@property NSColor *placedGuideColor;
@property NSColor *activeGuideColor;

@property NSColor *placedGrappleColor;
@property NSColor *previewGrappleColor;
@property NSColor *activeGrappleColor;

@property NSColor *placedRectangleFillColor;
@property NSColor *placedRectangleBorderColor;

@end
