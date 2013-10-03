//
//  DocumentController.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Foundation/Foundation.h>

@interface CanvasController : NSViewController

- (IBAction) addHorizontalGuideAtCursor:(id)sender;
- (IBAction) addVerticalGuideAtCursor:(id)sender;

@property (nonatomic, assign) ToolType selectedTool;

@end
