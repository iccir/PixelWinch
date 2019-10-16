//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "CaptureManager.h"

#import "AppDelegate.h"
#import "CanvasWindowController.h"
#import "Screenshot.h"
#import "Library.h"
#import "LibraryItem.h"



@interface CaptureManager ()
@end


@implementation CaptureManager {
    NSTask   *_task;
    LibraryItem *_currentItem;
}


- (void) keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
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


- (void) _startCapture
{
    if (_task) return;

    _currentItem = [LibraryItem libraryItem];
    if (!_currentItem) return;

    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/usr/sbin/screencapture"];
    [task setArguments:@[ @"-x", @"-i", @"-ttiff", [_currentItem screenshotPath] ]];
    
    _task = task;
    
    __weak id weakSelf = self;
    [task setTerminationHandler:^(NSTask *inTask) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf _taskDidTerminate:inTask];
        });
    }];

    [_task launch];
}


- (IBAction) captureSelection:(id)sender
{
    [self _startCapture];
}


@end
