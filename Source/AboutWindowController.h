//
//  AboutWindowController.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-10.
//
//

#import <Cocoa/Cocoa.h>

@interface AboutWindowController : NSWindowController

// Top-level objects
@property (nonatomic, strong) IBOutlet NSWindow *legalWindow;
@property (nonatomic, strong) IBOutlet NSTextView *legalText;

@property (nonatomic, weak) IBOutlet NSTextField *versionField;

- (IBAction) viewWebsite:(id)sender;
- (IBAction) viewOnAppStore:(id)sender;
- (IBAction) provideFeedback:(id)sender;
- (IBAction) viewAcknowledgements:(id)sender;

@end
