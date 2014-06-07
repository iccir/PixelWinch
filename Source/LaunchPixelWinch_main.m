//
//  main.m
//  LaunchAtLogin
//
//  Created by Ricci Adams on 2014-06-05.
//
//

#import <Cocoa/Cocoa.h>

@interface LaunchPixelWinchAppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation LaunchPixelWinchAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{

    NSArray *runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.pixelwinch.PixelWinch"];
    BOOL     needsLaunch         = [runningApplications count] == 0;
    
    if (needsLaunch) {
        NSString       *path       = [[NSBundle mainBundle] bundlePath];
        NSMutableArray *components = [[path pathComponents] mutableCopy];

        [components removeLastObject];
        [components removeLastObject];
        [components removeLastObject];
        [components removeLastObject];

        NSString *appPath = [NSString pathWithComponents:components];
        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }

    [NSApp terminate:nil];
}

@end


int main(int argc, const char * argv[])
{
@autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    LaunchPixelWinchAppDelegate *appDelegate = [[LaunchPixelWinchAppDelegate alloc] init];
    
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [application setDelegate:appDelegate];
    [application run];
    
}
    return 0;
}

