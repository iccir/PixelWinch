//
//  MasterController.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import <Foundation/Foundation.h>

@interface WinchWindowController : NSWindowController

- (void) presentWithImage:(CGImageRef)image screenRect:(CGRect)screenRect;

@property (strong) IBOutlet NSView *contentView;

@property (weak) IBOutlet NSView *toolContainer;
@property (weak) IBOutlet NSView *canvasContainer;
@property (weak) IBOutlet NSView *historyContainer;

@end
