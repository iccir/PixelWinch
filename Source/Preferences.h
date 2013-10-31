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

@property (nonatomic) BOOL pausesDuringCapture;
@property (nonatomic) BOOL usesPoints;

@property (nonatomic) Shortcut *captureSelectionShortcut;
@property (nonatomic) Shortcut *captureWindowShortcut;
@property (nonatomic) Shortcut *showScreenshotsShortcut;

@property (nonatomic) NSColor *placedGuideColor;
@property (nonatomic) NSColor *activeGuideColor;

@property (nonatomic) NSColor *placedGrappleColor;
@property (nonatomic) NSColor *previewGrappleColor;
@property (nonatomic) NSColor *activeGrappleColor;

@property (nonatomic) NSColor *placedRectangleFillColor;
@property (nonatomic) NSColor *placedRectangleBorderColor;

@end
