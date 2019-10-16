//
//  Preferences.m
//  Classic Color Meter
//
//  Created by Ricci Adams on 2011-07-17.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "Preferences.h"
#import "Shortcut.h"


NSString * const PreferencesDidChangeNotification = @"PreferencesDidChange";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static NSCoder *sMakeArchiver(NSMutableData *data)
{
    return [[NSArchiver alloc] initForWritingWithMutableData:data];
}

static NSCoder *sMakeUnarchiver(NSData *data)
{
    return [[NSUnarchiver alloc] initForReadingWithData:data];
}

#pragma clang diagnostic pop



static NSDictionary *sGetDefaultValues()
{
    static NSDictionary *sDefaultValues = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{

    sDefaultValues = @{
        @"iconMode":              @(IconModeInBoth),
        @"launchAtLogin":         @(NO),
        @"allowsQuit":            @(YES),

        @"captureSelectionShortcut":    [Shortcut emptyShortcut],
        @"importFromClipboardShortcut": [Shortcut emptyShortcut],
        @"showScreenshotsShortcut":     [Shortcut emptyShortcut],
        @"toggleScreenshotsShortcut":   [Shortcut emptyShortcut],
        @"closeScreenshotsKey":         @( CloseScreenshotsKeyCommandW ),
        
        @"customScaleMultiplier":     @"",

        @"scaleMode":                 @( 1 ),
        @"measurementCopyType":       @( 2 ),

        @"screenshotExpiration":      @( ScreenshotExpirationNever ),

        @"placedGuideColor":     GetRGBColor(0x00ffff, 1.0),
        @"activeGuideColor":     GetRGBColor(0x00d4ff, 1.0),

        @"previewGrappleColor":  GetRGBColor(0xff0080, 1.0),
        @"placedGrappleColor":   GetRGBColor(0xff0000, 1.0),
        @"activeGrappleColor":   GetRGBColor(0xff8000, 1.0),
        
        @"placedRectangleFillColor":   [NSColor colorWithCalibratedRed:0 green:0 blue:0.33 alpha:0.25],
        @"placedRectangleBorderColor": [NSColor whiteColor]
    };

    });
    
    return sDefaultValues;
}


static void sSetDefaultObject(id dictionary, NSString *key, id valueToSave, id defaultValue)
{
    void (^saveObject)(NSObject *, NSString *) = ^(NSObject *o, NSString *k) {
        if (o) {
            [dictionary setObject:o forKey:k];
        } else {
            [dictionary removeObjectForKey:k];
        }
    };

    if ([defaultValue isKindOfClass:[NSNumber class]] || [defaultValue isKindOfClass:[NSString class]]) {
        saveObject(valueToSave, key);

    } else if ([defaultValue isKindOfClass:[Shortcut class]]) {
        if (valueToSave == [Shortcut emptyShortcut]) {
            valueToSave = nil;
        }

        saveObject([valueToSave preferencesString], key);
       
    } else if ([defaultValue isKindOfClass:[NSColor class]]) {
        NSMutableData *data = nil;
        
        if (valueToSave) {
            data = [NSMutableData data];

            NSCoder *archiver = sMakeArchiver(data);
            [archiver encodeRootObject:valueToSave];
        }
        
        saveObject(data, key);
    }
}


static void sRegisterDefaults()
{
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

    NSDictionary *defaultValuesDictionary = sGetDefaultValues();
    for (NSString *key in defaultValuesDictionary) {
        id value = [defaultValuesDictionary objectForKey:key];
        sSetDefaultObject(defaults, key, value, value);
    }

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


@implementation Preferences


+ (id) sharedInstance
{
    static Preferences *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sRegisterDefaults();
        sSharedInstance = [[Preferences alloc] init];
    });
    
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        [self _load];
        
        for (NSString *key in sGetDefaultValues()) {
            [self addObserver:self forKeyPath:key options:0 context:NULL];
        }
    }

    return self;
}


- (void) _load
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    id (^loadObjectOfClass)(Class, NSString *) = ^(Class cls, NSString *key) {
        NSObject *o = [defaults objectForKey:key];
        return [o isKindOfClass:cls] ? o : nil;
    };

    NSDictionary *defaultValuesDictionary = sGetDefaultValues();
    for (NSString *key in defaultValuesDictionary) {
        id defaultValue = [defaultValuesDictionary objectForKey:key];

        if ([defaultValue isKindOfClass:[NSNumber class]]) {
            [self setValue:@([defaults integerForKey:key]) forKey:key];

        } else if ([defaultValue isKindOfClass:[NSString class]]) {
            NSString *value = [defaults stringForKey:key];
            if (value) [self setValue:value forKey:key];
        
        } else if ([defaultValue isKindOfClass:[Shortcut class]]) {
            NSString *preferencesString = [defaults objectForKey:key];
            Shortcut *shortcut          = nil;

            if ([preferencesString isKindOfClass:[NSString class]]) {
                shortcut = [Shortcut shortcutWithPreferencesString:preferencesString];
            }
            
            [self setValue:shortcut forKey:key];
            
        } else if ([defaultValue isKindOfClass:[NSColor class]]) {
            NSColor *result = nil;
            
            @try {
                NSData *data = loadObjectOfClass([NSData class], key);
                if (!data) continue;
                
                NSCoder *unarchiver = sMakeUnarchiver(data);
                if (!unarchiver) continue;

                result = [unarchiver decodeObject];

            } @catch (NSException *e) { }

            [self setValue:result forKey:key];
        }
    }
}


- (void) _save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *defaultValuesDictionary = sGetDefaultValues();
    for (NSString *key in defaultValuesDictionary) {
        id defaultValue = [defaultValuesDictionary objectForKey:key];
        id selfValue    = [self valueForKey:key];
        
        sSetDefaultObject(defaults, key, selfValue, defaultValue);
    }

    [defaults synchronize];
}


- (void) restoreDefaultColors
{
    NSDictionary *defaultValuesDictionary = sGetDefaultValues();

    for (NSString *key in defaultValuesDictionary) {
        id defaultValue = [defaultValuesDictionary objectForKey:key];

        if ([defaultValue isKindOfClass:[NSColor class]]) {
            [self setValue:defaultValue forKey:key];
        }
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesDidChangeNotification object:self];
        [self _save];
    }
}


@end
