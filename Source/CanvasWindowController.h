//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>
#import "Tool.h"

@class CanvasObject;
@class MagnificationManager;
@class Toolbox;
@class Library;
@class LibraryItem;
@class RulerView, CanvasView;

@interface CanvasWindowController : NSWindowController

- (BOOL) importFilesAtPaths:(NSArray *)filePaths;
- (BOOL) importImagesWithPasteboard:(NSPasteboard *)pasteboard;

- (void) presentLibraryItem:(LibraryItem *)libraryItem;
- (void) performToggleWindowShortcut;
- (void) activateAndShowWindow;
- (void) toggleVisibility;
- (void) saveCurrentLibraryItem;

- (BOOL) isWindowVisible;

@property (nonatomic) Toolbox *toolbox;

@property (nonatomic, readonly) Canvas *canvas;

@property (nonatomic, readonly) MagnificationManager *magnificationManager;


// Adapters for bindings
@property (nonatomic, weak) Preferences *preferences;
@property (nonatomic, weak) Library *library;

@property (nonatomic, strong) NSIndexSet *librarySelectionIndexes;

// Nib top-level objects
@property (nonatomic, strong) IBOutlet NSArrayController *libraryArrayController;
@property (nonatomic, strong) IBOutlet NSCollectionViewItem *libraryItemPrototype;


// Outlets
@property (nonatomic, weak) IBOutlet NSSegmentedControl *toolPicker;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *scalePicker;

@property (nonatomic, weak) IBOutlet NSScrollView *canvasScrollView;
@property (nonatomic, weak) IBOutlet CanvasView   *canvasView;
@property (nonatomic, weak) IBOutlet RulerView    *horizontalRuler;
@property (nonatomic, weak) IBOutlet RulerView    *verticalRuler;

@property (nonatomic, weak) IBOutlet NSScrollView *libraryScrollView;
@property (nonatomic, weak) IBOutlet NSCollectionView *libraryCollectionView;

// These need to be strong as they are going to be added/removed from subviews
@property (nonatomic, strong) IBOutlet NSToolbarItem *grappleToolbarItem;
@property (nonatomic, strong) IBOutlet NSToolbarItem *zoomToolbarItem;
@property (nonatomic, strong) IBOutlet NSPopUpButton *viewPopUpButton;


- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) zoomTo:(id)sender;

- (IBAction) duplicate:(id)sender;

- (IBAction) toggleGuides:(id)sender;

- (IBAction) loadPreviousLibraryItem:(id)sender;
- (IBAction) loadNextLibraryItem:(id)sender;
- (IBAction) deleteSelectedLibraryItem:(id)sender;

@end
