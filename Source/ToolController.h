//
//  ToolPaletteController.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Cocoa/Cocoa.h>
#import "Tool.h"

@class BlackSegmentedControl;
@class CanvasObject;
@class MoveTool, HandTool, MarqueeTool, RectangleTool, GrappleTool, ZoomTool;


@interface ToolController : NSViewController

- (void) selectToolWithType:(ToolType)type;

@property (strong) Tool *selectedTool;
@property (assign) NSInteger selectedToolIndex;

@property (strong) CanvasObject *selectedObject;

@property (strong, readonly) NSArray *allTools;

@property (strong, readonly) MoveTool      *moveTool;
@property (strong, readonly) HandTool      *handTool;
@property (strong, readonly) MarqueeTool   *marqueeTool;
@property (strong, readonly) RectangleTool *rectangleTool;
@property (strong, readonly) GrappleTool   *grappleTool;
@property (strong, readonly) ZoomTool      *zoomTool;

@property (weak) IBOutlet BlackSegmentedControl *segmentedControl;
@property (weak) IBOutlet NSView *inspectorContainer;

@property (strong) IBOutlet NSView *grappleToolView;
@property (strong) IBOutlet NSView *zoomToolView;

@property (strong) IBOutlet NSView *rectangleObjectView;

@end
