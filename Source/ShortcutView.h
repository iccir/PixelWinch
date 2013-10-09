//
//  ShortcutField.h
//  PixelWinch
//
//  Created by Ricci Adams on 4/22/11.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Shortcut;

@interface ShortcutView : NSControl 

@property (nonatomic, strong) Shortcut *shortcut;

@end
