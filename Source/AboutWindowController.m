//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "AboutWindowController.h"

@interface AboutWindowController ()

@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic, weak) IBOutlet NSTextField *versionField;

@property (nonatomic, weak) IBOutlet NSButton *viewOnAppStoreButton;

@end


@interface AboutWindowContentView : NSView
@end


@implementation AboutWindowContentView

- (void) drawRect:(NSRect)dirtyRect
{
    if (IsAppearanceDarkAqua(self)) {
        return;
    }

    NSColor *startingColor = GetRGBColor(0xe0e0e0, 1.0);
    NSColor *endingColor   = GetRGBColor(0xffffff, 1.0);

    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    [gradient drawInRect:[self bounds] angle:90];
}

@end


@implementation AboutWindowController


- (NSString *) windowNibName
{
    return @"About";
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    NSWindow *window = [self window];

    [[window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[window standardWindowButton:NSWindowZoomButton]        setHidden:YES];

    [window setTitlebarAppearsTransparent:YES];
    [window setTitleVisibility:NSWindowTitleHidden];

    [window setStyleMask:([window styleMask] | NSWindowStyleMaskFullSizeContentView)];
    
    NSView *contentView = [window contentView];
    
    NSRect windowFrame = [window frame];
    windowFrame.size = [contentView bounds].size;
    [window setFrame:windowFrame display:NO];

    [window setMovableByWindowBackground:YES];
    
    [contentView setFrame:[[contentView superview] bounds]];
    
    NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
    NSView   *closeSuperView = [closeButton superview];

    [closeButton removeFromSuperview];
    [closeSuperView addSubview:closeButton];  

#if ENABLE_BETA
    [[self imageView] setImage:[NSImage imageNamed:@"PixelWinch-Beta"]];

    __block NSString *expirationString = @"";
    __block long long expiration = kExpirationLong;
    
    ^{
        if (CFAbsoluteTimeGetCurrent() > expiration) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
                int *zero = (int *)(long)(rand() >> 31);
                *zero = 0;
            });

        } else {
            NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:expiration];

            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];
            
            expirationString = [formatter stringFromDate:date];
        }
    }();
    
    NSString *versionFormat = NSLocalizedString(@"Pixel Winch %@ Beta, Build %@\nThis build expires on %@", nil);

    id buildNumber  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    id shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    [[self versionField] setStringValue:[NSString stringWithFormat:versionFormat, shortVersion, buildNumber, expirationString]];
#else
    [[self imageView] setImage:[NSImage imageNamed:@"PixelWinch"]];

    NSString *versionFormat = NSLocalizedString(@"Pixel Winch %@, Build %@\nby Ricci Adams", nil);

    id buildNumber  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    id shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    [[self versionField] setStringValue:[NSString stringWithFormat:versionFormat, shortVersion, buildNumber]];
#endif
}


- (IBAction) viewWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchWebsiteURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewOnAppStore:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchAppStoreURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) provideFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchFeedbackURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewQuickGuide:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchGuideURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewPrivacy:(id)sender
{
    NSURL *url = [NSURL URLWithString:WinchPrivacyURLString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


@end
