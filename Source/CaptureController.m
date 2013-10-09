//
//  CaptureManager.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-27.
//
//

#import "CaptureController.h"
#import "CaptureView.h"
#import "Window.h"
#import "AppDelegate.h"
#import "WinchWindowController.h"

@interface CaptureController ()
@end


typedef struct {
    CGPoint downPoint;
    CGPoint upPoint;
} EventTapUserInfo;


static CGEventRef sEventTapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *rawUserInfo)
{
    EventTapUserInfo *userInfo = (EventTapUserInfo *)rawUserInfo;
    
    if (type == kCGEventLeftMouseDown || type == kCGEventRightMouseDown) {
        userInfo->downPoint = CGEventGetLocation(event);
    } else if (type == kCGEventLeftMouseUp || type == kCGEventRightMouseUp) {
        userInfo->upPoint = CGEventGetLocation(event);
    }

    return event;
}


@implementation CaptureController {
    NSTask   *_task;
    NSString *_path;

    CFMachPortRef      _eventTap;
    CFRunLoopSourceRef _eventTapRunLoopSource;
    EventTapUserInfo  *_eventTapUserInfo;
}


- (void) dealloc
{
    if (_eventTapRunLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _eventTapRunLoopSource, kCFRunLoopCommonModes);
        CFRelease(_eventTapRunLoopSource);
        _eventTapRunLoopSource = NULL;
    }

    if (_eventTap) {
        CGEventTapEnable(_eventTap, false);
        CFRelease(_eventTap);
        _eventTap = NULL;
    }
    
    free(_eventTapUserInfo);
}


- (void) keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
}


- (void) _taskDidTerminate:(NSTask *)task
{
    NSFileManager *manager = [NSFileManager defaultManager];

    BOOL isDirectory = NO;
    if (![manager fileExistsAtPath:_path isDirectory:&isDirectory] || isDirectory) {
        return;
    }

    NSData *data = [NSData dataWithContentsOfFile:_path];
    if (!data) return;

    NSImage *image = [[NSImage alloc] initWithData:data];
    if (!image) return;

    CGImageRef result = NULL;

    for (NSImageRep *rep in [image representations]) {
        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            result = CGImageRetain([(NSBitmapImageRep *)rep CGImage]);
        }
    }

    CGImageRelease(result);

    if (_eventTap) {
        CGEventTapEnable(_eventTap, false);
    }

    CGPoint downPoint = _eventTapUserInfo->downPoint;
    CGPoint upPoint   = _eventTapUserInfo->upPoint;

    if (downPoint.x < upPoint.x) {
        downPoint.x = floor(downPoint.x);
        upPoint.x   = ceil(upPoint.x);
    } else {
        downPoint.x = ceil(downPoint.x);
        upPoint.x   = floor(upPoint.x);
    }

    if (downPoint.y < upPoint.y) {
        downPoint.y = floor(downPoint.y);
        upPoint.y   = ceil(upPoint.y);
    } else {
        downPoint.y = ceil(downPoint.y);
        upPoint.y   = floor(upPoint.y);
    }

    CGRect rect = CGRectMake(downPoint.x, downPoint.y, upPoint.x - downPoint.x, upPoint.y - downPoint.y);
    rect = CGRectStandardize(rect);

    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    
    [[appDelegate winchController] presentWithImage:result screenRect:rect];

    [_task setTerminationHandler:nil];
    _task = nil;
}


- (void) _makeTap
{
    if (_eventTap) return;

    CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown)  |
                       CGEventMaskBit(kCGEventLeftMouseUp)    |
                       CGEventMaskBit(kCGEventRightMouseDown) |
                       CGEventMaskBit(kCGEventRightMouseUp);

    _eventTapUserInfo = calloc(1, sizeof(EventTapUserInfo));
    _eventTap = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly, mask, sEventTapCallBack, _eventTapUserInfo);
    _eventTapRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(), _eventTapRunLoopSource, kCFRunLoopCommonModes);

    CGEventTapEnable(_eventTap, true);
}


- (void) _startCapture
{
    if (_task) return;

    NSString *UUIDString = [[NSUUID UUID] UUIDString];
    NSString *filename   = [NSString stringWithFormat:@"%@.tiff", UUIDString];
    NSString *path       = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/usr/sbin/screencapture"];
    [task setArguments:@[ @"-s", @"-x", @"-i", @"-ttiff", path ]];
    
    _task = task;
    _path = path;
    
    __weak id weakSelf = self;
    [task setTerminationHandler:^(NSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf _taskDidTerminate:task];
        });
    }];

    if (!_eventTap) [self _makeTap];
    if (_eventTap) CGEventTapEnable(_eventTap, true);

    [_task launch];
}


- (IBAction) captureSelection:(id)sender
{
    [self _startCapture];
}


@end
