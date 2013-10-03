//
//  ToolPaletteController.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Cocoa/Cocoa.h>

@interface ToolController : NSViewController

- (IBAction) selectTool:(id)sender;

@property (weak) IBOutlet NSButton *moveButton;
@property (weak) IBOutlet NSButton *marqueeButton;
@property (weak) IBOutlet NSButton *boxLaserButton;
@property (weak) IBOutlet NSButton *zoomButton;

@property (assign) ToolType selectedTool;

@end
