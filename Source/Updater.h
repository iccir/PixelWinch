//
//  Updater.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2014-05-28.
//
//

#import <Foundation/Foundation.h>

#if !ENABLE_APP_STORE

@interface Updater : NSObject

+ (id) sharedInstance;

- (void) checkForUpdatesInForeground;
- (void) checkForUpdatesInBackground;

@end

#endif