//
//  Updater.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2014-05-28.
//
//

#import "Updater.h"

#if !ENABLE_APP_STORE

#import <Sparkle/SUUpdater.h>

@interface Updater () <SUVersionDisplay>
@end


@implementation Updater {
    SUUpdater *_updater;
}

+ (id) sharedInstance
{
    static Updater *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[Updater alloc] init];
    });
    
    return sSharedInstance;
}


+ (void) initialize
{
    NSString *sparklePath = [[NSBundle mainBundle] resourcePath];
    sparklePath = [sparklePath stringByDeletingLastPathComponent];
    sparklePath = [sparklePath stringByAppendingPathComponent:@"Frameworks"];
    sparklePath = [sparklePath stringByAppendingPathComponent:@"Sparkle.framework"];

    [[NSBundle bundleWithPath:sparklePath] load];

}

- (id) init
{
    if ((self = [super init])) {
        _updater = [NSClassFromString(@"SUUpdater") updaterForBundle:[NSBundle mainBundle]];
        [_updater setFeedURL:[NSURL URLWithString:@"<redacted>"]];

        [_updater setFeedURL:[NSURL URLWithString:@"<redacted>"]];
        [_updater setAutomaticallyChecksForUpdates:YES];
        [_updater checkForUpdatesInBackground];
        [_updater setSendsSystemProfile:NO];
        [_updater setDelegate:self];
    }

    return self;
}


- (void) checkForUpdatesInForeground
{
    [_updater checkForUpdates:nil];
}


- (void) checkForUpdatesInBackground
{
    [_updater checkForUpdatesInBackground];
}


- (id <SUVersionDisplay>)versionDisplayerForUpdater:(SUUpdater *)updater
{
    return self;
}

- (void) formatVersion:(NSString **)inOutVersionA andVersion:(NSString **)inOutVersionB
{
    NSString *(^format)(NSString *) = ^(NSString *inString) {
        NSInteger build = [inString integerValue];

        if ([inString isEqualToString:@"Public Beta"]) {
            build = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] integerValue];
        }

        return [NSString stringWithFormat:@"%C%ld", 0x03B2, (long)build];
    };

    *inOutVersionA = format(*inOutVersionA);
    *inOutVersionB = format(*inOutVersionB);
}


@end


#endif