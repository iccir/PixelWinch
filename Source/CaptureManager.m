//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "CaptureManager.h"

#import "AppDelegate.h"
#import "CanvasWindowController.h"
#import "Screenshot.h"
#import "Library.h"
#import "LibraryItem.h"


@interface CaptureManager ()
@end


static NSInteger sGetPermissionDialogCount(void)
{
    CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, 0);
    NSInteger count = 0;

    if (list) {
        for (NSInteger i = 0; i < CFArrayGetCount(list); i++) {
            CFDictionaryRef dictionary = CFArrayGetValueAtIndex(list, i);

            NSString *processName = (__bridge NSString *) CFDictionaryGetValue(dictionary, kCGWindowOwnerName);

            if ([processName containsString:@"universalAccess"]) {
                count++;
            }
        }
    }
    
    return count;
}


typedef NS_ENUM(NSInteger, CaptureManagerPermission) {
    CaptureManagerPermissionUnknown = -1,
    CaptureManagerPermissionDenied  = 0,
    CaptureManagerPermissionGranted = 1
};

@implementation CaptureManager {
    NSTask   *_task;
    LibraryItem *_currentItem;
}


- (void) keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
}


- (void) _showPermissionDialog
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:NSLocalizedString(@"Pixel Winch needs permission to record this computer's screen.", nil)];
    [alert setInformativeText:NSLocalizedString(@"Grant access to this application in Security & Privacy preferences, located in System Preferences.", nil)];

    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Open System Preferences", nil)];
    
    if ([alert runModal] == NSAlertSecondButtonReturn) {
        NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}


- (void) _taskDidTerminate:(NSTask *)task
{
    NSFileManager *manager = [NSFileManager defaultManager];

    NSString *path = [_currentItem screenshotPath];

    BOOL isDirectory = NO;
    if (![manager fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
        [[Library sharedInstance] discardItem:_currentItem];

        [_task setTerminationHandler:nil];
        _task = nil;

        return;
    }
    
    [[Library sharedInstance] addItem:_currentItem];

    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    [[appDelegate canvasWindowController] presentLibraryItem:_currentItem];

    [_task setTerminationHandler:nil];
    _task = nil;
}


- (CaptureManagerPermission) _currentPermission
{
    CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, 0);
    CaptureManagerPermission result = CaptureManagerPermissionUnknown;

    if (list) {
        for (NSInteger i = 0; i < CFArrayGetCount(list); i++) {
            CFDictionaryRef dictionary = CFArrayGetValueAtIndex(list, i);

            NSNumber *sharingType = (__bridge NSNumber *) CFDictionaryGetValue(dictionary, kCGWindowSharingState);
            NSNumber *windowLevel = (__bridge NSNumber *) CFDictionaryGetValue(dictionary, kCGWindowLayer);
            NSString *processName = (__bridge NSString *) CFDictionaryGetValue(dictionary, kCGWindowOwnerName);

            if ([processName isEqualToString:@"Dock"]) {
                if ([windowLevel integerValue] == kCGDockWindowLevel) {
                    if ([sharingType integerValue] == kCGWindowSharingNone) {
                        result = CaptureManagerPermissionDenied;
                    } else {
                        result = CaptureManagerPermissionGranted;
                    }
                    
                    break;
                }
            }
        }
    
        CFRelease(list);
    }
    
    return result;
}



- (void) _startCapture
{
    if (_task) return;

    _currentItem = [LibraryItem libraryItem];
    if (!_currentItem) return;

    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/usr/sbin/screencapture"];
    [task setArguments:@[ @"-x", @"-i", @"-ttiff", [_currentItem screenshotPath] ]];
       
    __weak id weakSelf = self;
    [task setTerminationHandler:^(NSTask *inTask) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf _taskDidTerminate:inTask];
        });
    }];

    _task = task;
    [_task launch];
}


- (IBAction) captureSelection:(id)sender
{
    CaptureManagerPermission permission = CaptureManagerPermissionGranted;
    
    if (@available(macOS 10.15, *)) {
        permission = [self _currentPermission];
    }

    if (permission == CaptureManagerPermissionDenied) {
        NSInteger initialCount = sGetPermissionDialogCount();

        __weak __auto_type weakSelf = self;
        
        // Trigger screen capture
        CGImageRef image = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionAll, 0, kCGWindowImageDefault);
        CGImageRelease(image);

        // Wait 250ms and check count again
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(250 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            if (sGetPermissionDialogCount() <= initialCount) {
                [weakSelf _showPermissionDialog];
            }
        });

    } else {
        [self _startCapture];
    }
}


@end
