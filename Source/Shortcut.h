//
//  Shortcut.h
//  PixelWinch
//
//  Created by Ricci Adams on 4/23/11.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Shortcut : NSObject

+ (NSString *) stringForModifierFlags:(NSUInteger)modifierFlags;
+ (NSString *) stringForKeyCode:(unsigned short)keyCode;

+ (Shortcut *) shortcutWithPreferencesString:(NSString *)string;
+ (Shortcut *) shortcutWithWithKeyCode:(unsigned short)keycode modifierFlags:(NSUInteger)modifierFlags;

+ (Shortcut *) emptyShortcut;

- (id) initWithPreferencesString:(NSString *)string;
- (id) initWithKeyCode:(unsigned short)keycode modifierFlags:(NSUInteger)modifierFlags;

@property (nonatomic, readonly) NSUInteger shortcutID;
@property (nonatomic, readonly) NSUInteger modifierFlags;
@property (nonatomic, readonly) unsigned short keyCode;

@property (nonatomic, strong, readonly) NSString *preferencesString;
@property (nonatomic, strong, readonly) NSString *displayString;

@property (nonatomic, readonly, getter=isValid) BOOL valid;

@end
