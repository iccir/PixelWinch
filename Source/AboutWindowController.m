//
//  AboutWindowController.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-10.
//
//

#import "AboutWindowController.h"
#import "Expiration.h"
#import "Updater.h"

@interface AboutWindowController ()

@end

@interface AboutWindowContentView : NSView
@end


@implementation AboutWindowContentView

- (void) drawRect:(NSRect)dirtyRect
{
    NSColor *startingColor = GetRGBColor(0xe0e0e0, 1.0);
    NSColor *endingColor   = GetRGBColor(0xffffff, 1.0);

    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
    [gradient drawInRect:[self bounds] angle:90];
}

@end


@implementation AboutWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

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

    if (!IsLegacyOS()) {
        [window setTitlebarAppearsTransparent:YES];
        [window setTitleVisibility:NSWindowTitleHidden];

        [window setStyleMask:([window styleMask] | NSFullSizeContentViewWindowMask)];
    }
    
    NSView *contentView = [window contentView];
    
    NSRect windowFrame = [window frame];
    windowFrame.size = [contentView bounds].size;
    [window setFrame:windowFrame display:NO];

    [window setMovableByWindowBackground:YES];
    
    [contentView setFrame:[[contentView superview] bounds]];
    
    NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
    [[closeButton superview] bringSubviewToFront:closeButton];

    NSString *versionFormat = NSLocalizedString(@"Pixel Winch %@, Build %@\n%@", nil);
    id buildNumber  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    id shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

#if ENABLE_APP_STORE
    NSString *betaString = @"";
#else
    [[self viewOnAppStoreButton] setTitle:NSLocalizedString(@"Check for Updates", nil)];

    __block NSString *timeRemaining = @"";
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
            
            timeRemaining = [formatter stringFromDate:date];
        }
    }();

    NSString *betaString = [NSString stringWithFormat:@"Beta expires on %@", timeRemaining];
#endif

    [[self versionField] setStringValue:[NSString stringWithFormat:versionFormat, shortVersion, buildNumber, betaString]];

    NSScrollView *legalScrollView = [[self legalText] enclosingScrollView];

    [legalScrollView setHasVerticalScroller:YES];
    [legalScrollView setScrollerStyle:NSScrollerStyleLegacy];
    [legalScrollView setHasHorizontalScroller:NO];

    NSString *legalPath = [[NSBundle mainBundle] pathForResource:@"Legal" ofType:@"rtf"];
    [[self legalText] readRTFDFromFile:legalPath];

    NSRect frame = [[self legalText] frame];
    frame.size.width -= 20;
    [[self legalText] setFrame:frame];
}


- (IBAction) viewWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchWebsiteURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewOnAppStore:(id)sender
{
#if ENABLE_APP_STORE
    NSURL *url = [NSURL URLWithString:GetPixelWinchOnAppStoreURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
#else
   [[Updater sharedInstance] checkForUpdatesInForeground];
#endif
}


- (IBAction) provideFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchFeedbackURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewAcknowledgements:(id)sender
{
    [[self legalWindow] center];
    [[self window] orderOut:self];
    [[self legalWindow] makeKeyAndOrderFront:self];
}


@end
