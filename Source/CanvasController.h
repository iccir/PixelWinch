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
@class Toolbox;
@class Library;
@class LibraryItem;
@class RulerView, CanvasView, ShroudView;

@interface CanvasController : NSWindowController

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromGlobalRect:(CGRect)fromRect;
- (void) toggleVisibility;
- (void) saveCurrentLibraryItem;

@property (nonatomic) Toolbox *toolbox;

@property (nonatomic, readonly) Canvas *canvas;


@property (nonatomic, weak)   Library *library; // So we can bind to it
@property (nonatomic, strong) CanvasObject *selectedObject;   // So we can bind to it
@property (nonatomic, strong) NSIndexSet *librarySelectionIndexes;

// Nib top-level objects
@property (nonatomic, strong) IBOutlet ShroudView *contentTopLevelView;
@property (nonatomic, strong) IBOutlet NSView *inspectorTopLevelView;

@property (nonatomic, strong) IBOutlet NSArrayController *libraryArrayController;
@property (nonatomic, strong) IBOutlet NSCollectionViewItem *libraryItemPrototype;


// Outlets
@property (nonatomic, weak) IBOutlet BlackSegmentedControl *toolPicker;
@property (nonatomic, weak) IBOutlet NSView *inspectorContainer;

@property (nonatomic, weak) IBOutlet NSScrollView *canvasScrollView;
@property (nonatomic, weak) IBOutlet CanvasView   *canvasView;
@property (nonatomic, weak) IBOutlet RulerView    *horizontalRuler;
@property (nonatomic, weak) IBOutlet RulerView    *verticalRuler;

@property (nonatomic, weak) IBOutlet NSScrollView *libraryScrollView;
@property (nonatomic, weak) IBOutlet NSCollectionView *libraryCollectionView;

// These need to be strong as they are going to be added/removed from subviews
@property (nonatomic, strong) IBOutlet NSView *grappleToolView;
@property (nonatomic, strong) IBOutlet NSView *zoomToolView;
@property (nonatomic, strong) IBOutlet NSView *rectangleObjectView;

- (IBAction) selectPreviousLibraryItem:(id)sender;
- (IBAction) selectNextLibraryItem:(id)sender;
- (IBAction) deleteSelectedLibraryItem:(id)sender;

@end
