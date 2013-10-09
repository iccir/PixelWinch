//
//  DocumentController.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Foundation/Foundation.h>

@class Tool, ZoomTool, CanvasObject;

@interface CanvasController : NSViewController

- (IBAction) addHorizontalGuideAtCursor:(id)sender;
- (IBAction) addVerticalGuideAtCursor:(id)sender;

@property Tool *selectedTool;
@property ZoomTool *zoomTool;
@property CanvasObject *selectedObject;

- (BOOL) deleteSelectedObjects;

@end
