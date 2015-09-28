//
//  AboutWindowController.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-10.
//
//

#import "AboutWindowController.h"

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

#if ENABLE_APP_STORE
    [[self imageView] setImage:[NSImage imageNamed:@"PixelWinch"]];

    NSString *versionFormat = NSLocalizedString(@"Pixel Winch %@, Build %@\nby Ricci Adams", nil);

    id buildNumber  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    id shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    [[self versionField] setStringValue:[NSString stringWithFormat:versionFormat, shortVersion, buildNumber]];

#elif ENABLE_BETA
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
    [[self imageView] setImage:[NSImage imageNamed:@"PixelWinch-Trial"]];

    NSString *versionFormat = NSLocalizedString(@"Pixel Winch %@, Build %@\nTrial Version", nil);

    id buildNumber  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    id shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    [[self versionField] setStringValue:[NSString stringWithFormat:versionFormat, shortVersion, buildNumber]];

    [[self viewOnAppStoreButton] setTitle:NSLocalizedString(@"Purchase Pixel Winch", nil)];
#endif

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
    NSURL *url = [NSURL URLWithString:GetPixelWinchOnAppStoreURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) provideFeedback:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchFeedbackURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewQuickGuide:(id)sender
{
    NSURL *url = [NSURL URLWithString:GetPixelWinchGuideURLString()];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) viewAcknowledgements:(id)sender
{
    [[self legalWindow] center];
    [[self window] orderOut:self];
    [[self legalWindow] makeKeyAndOrderFront:self];
}


@end
