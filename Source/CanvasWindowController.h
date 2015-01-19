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
@class MagnificationManager;
@class Toolbox;
@class Library;
@class LibraryItem;
@class RulerView, CanvasView, ContentView, WindowResizerKnob;

@interface CanvasWindowController : NSWindowController

- (BOOL) importFilesAtPaths:(NSArray *)filePaths;

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromGlobalRect:(CGRect)fromRect;
- (void) toggleVisibility;
- (void) saveCurrentLibraryItem;
- (void) hideIfOverlay;

- (BOOL) isWindowVisible;

@property (nonatomic) Toolbox *toolbox;

@property (nonatomic, readonly) Canvas *canvas;

@property (nonatomic, readonly) MagnificationManager *magnificationManager;


// Adapters for bindings
@property (nonatomic, weak) Preferences *preferences;
@property (nonatomic, weak) Library *library;
@property (nonatomic, strong) CanvasObject *selectedObject;

@property (nonatomic, strong) NSIndexSet *librarySelectionIndexes;

// Nib top-level objects
@property (nonatomic, strong) IBOutlet NSView *inspectorTopLevelView;

@property (nonatomic, strong) IBOutlet NSArrayController *libraryArrayController;
@property (nonatomic, strong) IBOutlet NSCollectionViewItem *libraryItemPrototype;

@property (nonatomic, strong) IBOutlet NSView *topView;
@property (nonatomic, strong) IBOutlet NSView *bottomView;


// Outlets
@property (nonatomic, weak) IBOutlet BlackSegmentedControl *toolPicker;
@property (nonatomic, weak) IBOutlet NSView *inspectorContainer;
@property (nonatomic, weak) IBOutlet BlackSegmentedControl *scalePicker;

@property (nonatomic, weak) IBOutlet NSScrollView *canvasScrollView;
@property (nonatomic, weak) IBOutlet CanvasView   *canvasView;
@property (nonatomic, weak) IBOutlet RulerView    *horizontalRuler;
@property (nonatomic, weak) IBOutlet RulerView    *verticalRuler;

@property (nonatomic, weak) IBOutlet WindowResizerKnob *resizerKnob;

@property (nonatomic, weak) IBOutlet NSScrollView *libraryScrollView;
@property (nonatomic, weak) IBOutlet NSCollectionView *libraryCollectionView;

// These need to be strong as they are going to be added/removed from subviews
@property (nonatomic, strong) IBOutlet NSView *grappleToolView;
@property (nonatomic, strong) IBOutlet NSView *zoomToolView;
@property (nonatomic, strong) IBOutlet NSView *rectangleObjectView;

- (IBAction) showGrappleHelp:(id)sender;

- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) zoomTo:(id)sender;

- (IBAction) toggleGuides:(id)sender;

- (IBAction) loadPreviousLibraryItem:(id)sender;
- (IBAction) loadNextLibraryItem:(id)sender;
- (IBAction) deleteSelectedLibraryItem:(id)sender;

@end
