//
//  DocumentController.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Foundation/Foundation.h>
#import "Tool.h"

@class BlackSegmentedControl;
@class CanvasObject;
@class Tool, MoveTool, HandTool, MarqueeTool, RectangleTool, GrappleTool, ZoomTool;

@class Library;
@class LibraryItem;
@class RulerView, CanvasView, ShroudView;

@interface CanvasController : NSWindowController

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromRect:(CGRect)fromRect;
- (void) presentWithLastImage;

@property Tool *selectedTool;
@property NSInteger selectedToolIndex;

@property (strong) CanvasObject *selectedObject;

@property (weak)   Library *library; // So we can bind to it
@property (strong) NSIndexSet *librarySelectionIndexes;

@property (strong, readonly) NSArray       *allTools;
@property (strong, readonly) MoveTool      *moveTool;
@property (strong, readonly) HandTool      *handTool;
@property (strong, readonly) MarqueeTool   *marqueeTool;
@property (strong, readonly) RectangleTool *rectangleTool;
@property (strong, readonly) GrappleTool   *grappleTool;
@property (strong, readonly) ZoomTool      *zoomTool;

// Nib top-level objects
@property (strong) IBOutlet ShroudView *contentTopLevelView;
@property (strong) IBOutlet NSView *inspectorTopLevelView;

@property (strong) IBOutlet NSArrayController *libraryArrayController;
@property (strong) IBOutlet NSCollectionViewItem *libraryItemPrototype;


// Outlets
@property (weak) IBOutlet BlackSegmentedControl *toolPicker;
@property (weak) IBOutlet NSView *inspectorContainer;

@property (weak) IBOutlet NSScrollView *canvasScrollView;
@property (weak) IBOutlet CanvasView   *canvasView;
@property (weak) IBOutlet RulerView    *horizontalRuler;
@property (weak) IBOutlet RulerView    *verticalRuler;

@property (weak) IBOutlet NSScrollView *libraryScrollView;
@property (weak) IBOutlet NSCollectionView *libraryCollectionView;

// These need to be strong as they are going to be added/removed from subviews
@property (strong) IBOutlet NSView *grappleToolView;
@property (strong) IBOutlet NSView *zoomToolView;
@property (strong) IBOutlet NSView *rectangleObjectView;


@end
