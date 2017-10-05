//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Cocoa/Cocoa.h>

@interface AboutWindowController : NSWindowController

// Top-level objects
@property (nonatomic, strong) IBOutlet NSWindow *legalWindow;
@property (nonatomic, strong) IBOutlet NSTextView *legalText;

@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic, weak) IBOutlet NSTextField *versionField;

@property (nonatomic, weak) IBOutlet NSButton *viewOnAppStoreButton;

- (IBAction) viewWebsite:(id)sender;
- (IBAction) viewOnAppStore:(id)sender;
- (IBAction) provideFeedback:(id)sender;
- (IBAction) viewQuickGuide:(id)sender;
- (IBAction) viewAcknowledgements:(id)sender;

@end
