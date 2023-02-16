//
//  Migration.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2023-02-03.
//

#import "Migration.h"


NSString *DidMigrateDataKey    = @"did-migrate-data-from-mas";
NSString *DidMigrateLicenseKey = @"did-migrate-license-from-mas";


#pragma mark - Data Migration

static NSURL *sGetLegacyLibraryURL(void)
{
    NSString *path = @"~/Library/Containers/com.pixelwinch.PixelWinch/Data/Library";
    return [NSURL fileURLWithPath:[path stringByExpandingTildeInPath] isDirectory:YES];
}


static NSURL *sGetLegacyScreenshotsURL(void)
{
    NSURL *result = sGetLegacyLibraryURL();

    result = [result URLByAppendingPathComponent:@"Application Support" isDirectory:YES];
    result = [result URLByAppendingPathComponent:@"Pixel Winch" isDirectory:YES];
    result = [result URLByAppendingPathComponent:@"Screenshots" isDirectory:YES];
    
    return result;
}


static NSURL *sGetLegacyPlistURL(void)
{
    NSURL *result = sGetLegacyLibraryURL();

    result = [result URLByAppendingPathComponent:@"Preferences" isDirectory:YES];
    result = [result URLByAppendingPathComponent:@"com.pixelwinch.PixelWinch.plist" isDirectory:NO];

    return result;
}


static BOOL sMigrateLegacyPlist()
{
    NSError *error = nil;

    NSURL   *plistURL  = sGetLegacyPlistURL();
    NSData  *plistData = [NSData dataWithContentsOfURL:plistURL options:0 error:&error];
    
    if (error) {
        WinchWarn(@"Migration", @"Could not load data from %@: %@", plistURL, error);
        return NO;
    }
    
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:&error];

    if (error) {
        WinchWarn(@"Migration", @"Could not deserialize %@: %@", plistURL, error);
        return NO;
    }
    
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        WinchWarn(@"Migration", @"plist was not a dictionary %@", plistURL);
        return NO;
    }

    for (NSString *key in [dictionary allKeys]) {
        [[NSUserDefaults standardUserDefaults] setObject:[dictionary objectForKey:key] forKey:key];
    }

    return YES;
}


static BOOL sMigrateLegacyScreenshots()
{
    NSError *error = nil;

    NSString *screenshotsDirectory = GetScreenshotsDirectory();
    [[NSFileManager defaultManager] createDirectoryAtPath:screenshotsDirectory withIntermediateDirectories:YES attributes:nil error:&error];

    NSURL *oldScreenshotsURL = sGetLegacyScreenshotsURL();
    NSURL *newScreenshotsURL = [NSURL fileURLWithPath:screenshotsDirectory isDirectory:YES];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *oldScreenshots = [fileManager contentsOfDirectoryAtURL: oldScreenshotsURL 
                                         includingPropertiesForKeys: nil
                                                            options: NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                              error: &error];
    
    for (NSURL *oldScreenshot in oldScreenshots) {
        NSURL *newScreenshot = [newScreenshotsURL URLByAppendingPathComponent:[oldScreenshot lastPathComponent]];
        
        if (![fileManager fileExistsAtPath:[newScreenshot path]]) {
            [fileManager copyItemAtURL:oldScreenshot toURL:newScreenshot error:&error];
        }
    }

    return YES;
}


@implementation Migration


+ (BOOL) needsMigration
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL didMigrateData    = [defaults boolForKey:DidMigrateDataKey];
    BOOL didMigrateLicense = [defaults boolForKey:DidMigrateLicenseKey];
    
    [defaults setBool:didMigrateData    forKey:DidMigrateDataKey];
    [defaults setBool:didMigrateLicense forKey:DidMigrateLicenseKey];

    return !didMigrateLicense;
}


+ (void) migrate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults boolForKey:DidMigrateDataKey]) {
        sMigrateLegacyPlist();
        sMigrateLegacyScreenshots();
    
        [defaults setBool:YES forKey:DidMigrateDataKey];
    }
    
    [defaults setBool:YES forKey:DidMigrateLicenseKey];
}
    

+ (BOOL) isValidReceiptData:(NSData *)data
{
    const char *bundleID = "com.pixelwinch.PixelWinch";
    size_t bundleIDLength = strlen(bundleID);
    
    void *location = memmem([data bytes], [data length], bundleID, bundleIDLength);
    
    return location != NULL;
}

@end
