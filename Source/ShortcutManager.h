//
//  ShortcutManager.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2011-05-01.
//  Copyright 2011-2013 Ricci Adams. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol ShortcutListener;

@class Shortcut;
@class ShortcutView;

@interface ShortcutManager : NSObject

+ (BOOL) hasSharedInstance;
+ (id) sharedInstance;

- (void) addListener:(id<ShortcutListener>)listener;
- (void) removeListener:(id<ShortcutListener>)listener;

@property (nonatomic, copy) NSArray *shortcuts;

@end


@protocol ShortcutListener <NSObject>
- (BOOL) performShortcut:(Shortcut *)shortcut;
@end