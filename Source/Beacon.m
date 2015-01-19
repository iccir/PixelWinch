
//
//  IXBeacon.m
//  IXCore
//
//  Created by Ricci Adams on 2012-03-11.
//  Copyright (c) 2012-2014 Ricci Adams. All rights reserved.
//


#import "Beacon.h"


static const NSTimeInterval sBeaconInitialUpdateInterval    = 60 * 60 * 2;      // 2 hours
static const NSTimeInterval sBeaconSuccessfulUpdateInterval = 60 * 60 * 24;     // 1 day
static const NSTimeInterval sBeaconFailedUpdateInterval     = 60 * 60;          // 1 hour

static NSString * const sBeaconKey = @"Beacon";


static void sSetNextUpdateInterval(NSTimeInterval offsetFromNow)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval  now      = [NSDate timeIntervalSinceReferenceDate];

    [defaults setObject:[NSNumber numberWithDouble:(now + offsetFromNow)] forKey:sBeaconKey];
    [defaults synchronize];
}
    

static void sBeaconDidFinish(BOOL successful)
{
    if (successful) {
        sSetNextUpdateInterval(sBeaconSuccessfulUpdateInterval);
    } else {
        sSetNextUpdateInterval(sBeaconFailedUpdateInterval);
    }
}


static BOOL sIsBeaconReady()
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:sBeaconKey];

    if (![number isKindOfClass:[NSNumber class]]) {
        sSetNextUpdateInterval(sBeaconInitialUpdateInterval);
        return NO;
    } 

    NSTimeInterval updateInterval = [number doubleValue];
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    return now >= updateInterval;
}


void BeaconActivate(NSURL *url, BOOL force)
{
    if (force || sIsBeaconReady()) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

            NSBundle *mainBundle  = [NSBundle mainBundle];
            NSString *identifier  = [mainBundle objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
            NSString *buildNumber = [mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
            
            NSString *userAgent = [NSString stringWithFormat:@"%@ Beta %@", identifier, buildNumber];

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            static NSString * const key = @"BeaconUUID";

            NSString *UUIDString = [defaults objectForKey:key];
            if (!UUIDString) {
                UUIDString = [[NSUUID UUID] UUIDString];
                [defaults setObject:UUIDString forKey:key];
                [defaults synchronize];
            }

            NSString *beaconString = [NSString stringWithFormat:@"%@|%ld", UUIDString, (long)(IsLegacyOS() ? 9 : 10)];
            
            [request setValue:beaconString forHTTPHeaderField:@"X-Beacon"];
            [request setValue:userAgent    forHTTPHeaderField:@"User-Agent"];

            NSURLResponse *response = nil;
            NSError       *error    = nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

            NSHTTPURLResponse *httpResponse = nil;

            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                httpResponse = (NSHTTPURLResponse *)response;
            }

            if (!force) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    sBeaconDidFinish(!error && ([httpResponse statusCode] == 200));
                });
            }
        });
    }
}

