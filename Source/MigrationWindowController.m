//
//  MigrationWindowController.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2023-02-08.
//

#import "MigrationWindowController.h"
#import "Migration.h"

@interface MigrationWindowController ()

@property (nonatomic, weak) IBOutlet NSImageView *imageWell;
@property (nonatomic, weak) IBOutlet NSButton *migrateButton;

@property (nonatomic, weak) IBOutlet NSTextField *statusField;
@property (nonatomic, weak) IBOutlet NSImageView *statusImageView;

@end


@implementation MigrationWindowController 

- (void) windowDidLoad
{
    [[self migrateButton] setEnabled:NO];

    [[self imageWell] unregisterDraggedTypes];

    [[self window] registerForDraggedTypes:@[ NSPasteboardTypeURL ]];
}


- (NSArray<NSURL *> *) _applicationURLArrayWithDraggingInfo:(id <NSDraggingInfo>)info
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    return [pasteboard readObjectsForClasses:@[ [NSURL class] ] options:@{
        NSPasteboardURLReadingFileURLsOnlyKey: @YES,
        NSPasteboardURLReadingContentsConformToTypesKey: @[ @"com.apple.bundle" ]
    }];
}


- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)info
{
    return [[self _applicationURLArrayWithDraggingInfo:info] count] > 0 ?
        NSDragOperationCopy :
        NSDragOperationNone;
}


- (BOOL) performDragOperation:(id <NSDraggingInfo>)info
{
    NSURL *URL = [[self _applicationURLArrayWithDraggingInfo:info] firstObject];
    
    [self _selectURL:URL];

    return URL != nil;
}


- (void) _setValid:(BOOL)valid text:(NSString *)text
{
    NSImageView *statusImageView = [self statusImageView];

    NSColor *color = nil;

    if (valid) {
        [statusImageView setImage:[NSImage imageWithSystemSymbolName:@"checkmark.seal.fill" accessibilityDescription:@""]];
        [statusImageView setSymbolConfiguration:[NSImageSymbolConfiguration configurationWithScale:NSImageSymbolScaleLarge]];
        [statusImageView setHidden:NO];
    
        color = [NSColor systemGreenColor];

    } else {
        [statusImageView setImage:[NSImage imageWithSystemSymbolName:@"exclamationmark.triangle.fill" accessibilityDescription:@""]];
        [statusImageView setSymbolConfiguration:[NSImageSymbolConfiguration configurationWithScale:NSImageSymbolScaleLarge]];
        [statusImageView setHidden:NO];

        color = [NSColor systemYellowColor];
    }

    if (color) {
        [statusImageView setContentTintColor:color];
        [[self statusField] setTextColor:color];
    }

    [[self statusField] setHidden:([text length] == 0)];
    [[self statusField] setStringValue:text ? text : @""];
}


- (void) _selectURL:(NSURL *)URL
{
    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:[URL path]];
    
    [image setSize:NSMakeSize(72, 72)];
    [[self imageWell] setImage:image];
   
    [[self migrateButton] setEnabled:NO];

    NSURL *executableURL = [[[URL
            URLByAppendingPathComponent:@"Contents" isDirectory:YES]
            URLByAppendingPathComponent:@"MacOS" isDirectory:YES]
            URLByAppendingPathComponent:@"Pixel Winch" isDirectory:NO];

    NSURL *receiptURL = [[[URL
            URLByAppendingPathComponent:@"Contents" isDirectory:YES]
            URLByAppendingPathComponent:@"_MASReceipt" isDirectory:YES]
            URLByAppendingPathComponent:@"receipt" isDirectory:NO];

    NSData *executableData = executableURL ? [NSData dataWithContentsOfURL:executableURL] : nil;
    NSData *receiptData    = receiptURL    ? [NSData dataWithContentsOfURL:receiptURL]    : nil;

    if ([executableData length] == 0) {
        [self _setValid:NO text:@"The selected app is not Pixel Winch."];

    } else if ([[[NSBundle bundleWithURL:URL] bundleIdentifier] isEqualToString:@"com.iccir.PixelWinch"]) {
        [self _setValid:NO text:@"This is not the Mac App Store version of Pixel Winch."];
    
    } else if ([receiptData length] == 0) {
        [self _setValid:NO text:@"The Mac App Store receipt is missing."];
    
    } else if (![Migration isValidReceiptData:receiptData]) {
        [self _setValid:NO text:@"The Mac App Store receipt is corrupted."];

    } else {
        [self _setValid:YES text:@"Your original purchase was validated."];
        [[self migrateButton] setEnabled:YES];
    }
}


- (IBAction) quit:(id)sender
{
    [NSApp terminate:self];
}


- (IBAction) migrate:(id)sender
{
    [NSApp stopModalWithCode:NSModalResponseOK];
}

@end
