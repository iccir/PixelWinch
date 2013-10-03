//
//  PixelsAppDelegate.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-09-27.
//  Copyright 2013 Ricci Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSResponder <NSApplicationDelegate>

- (void) loadStateFromPreferences;
- (void) saveStateToPreferences;

@end
