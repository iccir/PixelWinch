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

- (void) presentLibraryItem:(LibraryItem *)libraryItem fromRect:(CGRect)fromRect;
- (void) toggleVisibility;
- (void) saveCurrentLibraryItem;

@property Toolbox *toolbox;

@property (nonatomic, strong) CanvasObject *selectedObject;

@property (weak)   Library *library; // So we can bind to it
@property (strong) NSIndexSet *librarySelectionIndexes;

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
