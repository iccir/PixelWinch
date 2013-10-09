//
//  ToolPaletteController.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "ToolController.h"
#import "BlackSegmentedControl.h"

#import "MoveTool.h"
#import "HandTool.h"
#import "MarqueeTool.h"
#import "RectangleTool.h"
#import "GrappleTool.h"
#import "ZoomTool.h"

#import "Rectangle.h"

@interface ToolController ()

@end

@implementation ToolController {
    Tool *_selectedTool;
    CanvasObject *_selectedObject;
    NSInteger _selectedToolIndex;
}

- (NSString *) nibName
{
    return @"ToolPalette";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _moveTool      = [[MoveTool      alloc] init];
        _handTool      = [[HandTool      alloc] init];
        _marqueeTool   = [[MarqueeTool   alloc] init];
        _rectangleTool = [[RectangleTool alloc] init];
        _grappleTool   = [[GrappleTool   alloc] init];
        _zoomTool      = [[ZoomTool      alloc] init];
    }

    return self;
}


+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;

    if ([key isEqualToString:@"selectedTool"]) {
        affectingKeys = @[ @"selectedToolIndex" ];
    } else if ([key isEqualToString:@"selectedToolIndex"]) {
        affectingKeys = @[ @"selectedTool" ];
    }
    
    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    
    return keyPaths;
}


- (void) awakeFromNib
{
    NSImage *arrowSelected     = [NSImage imageNamed:@"toolbar_arrow_selected"];
    NSImage *handSelected      = [NSImage imageNamed:@"toolbar_hand_selected"];
    NSImage *marqueeSelected   = [NSImage imageNamed:@"toolbar_marquee_selected"];
    NSImage *rectangleSelected = [NSImage imageNamed:@"toolbar_rectangle_selected"];
    NSImage *grappleSelected   = [NSImage imageNamed:@"toolbar_grapple_selected"];
    NSImage *zoomSelected      = [NSImage imageNamed:@"toolbar_zoom_selected"];

    [_segmentedControl setSelectedImage:arrowSelected     forSegment:0];
    [_segmentedControl setSelectedImage:handSelected      forSegment:1];
    [_segmentedControl setSelectedImage:marqueeSelected   forSegment:2];
    [_segmentedControl setSelectedImage:rectangleSelected forSegment:3];
    [_segmentedControl setSelectedImage:grappleSelected   forSegment:4];
    [_segmentedControl setSelectedImage:zoomSelected      forSegment:5];
}


- (NSArray *) allTools
{
    return @[ _moveTool, _handTool, _marqueeTool, _rectangleTool, _grappleTool, _zoomTool ];
}


- (void) _updateInspector
{
    ToolType type = [[self selectedTool] type];
    NSView *view = nil;

    if (type == ToolTypeZoom) {
        view = [self zoomToolView];
    } else if (type == ToolTypeGrapple) {
        view = [self grappleToolView];
    } else if ([_selectedObject isKindOfClass:[Rectangle class]]) {
        view = [self rectangleObjectView];
    }
    
    NSLog(@"%@", view);

    if ([view superview] != _inspectorContainer) {
        NSArray *subviews = [[_inspectorContainer subviews] copy];

        for (NSView *subview in subviews) {
            [subview removeFromSuperview];
        }
        
        [_inspectorContainer addSubview:view];
        [view setFrame:[_inspectorContainer bounds]];
    }
}


- (void) selectToolWithType:(ToolType)type
{
    if (type == ToolTypeMove) {
        [self setSelectedTool:_moveTool];
    } else if (type == ToolTypeHand) {
        [self setSelectedTool:_handTool];
    } else if (type == ToolTypeMarquee) {
        [self setSelectedTool:_marqueeTool];
    } else if (type == ToolTypeRectangle) {
        [self setSelectedTool:_rectangleTool];
    } else if (type == ToolTypeGrapple) {
        [self setSelectedTool:_grappleTool];
    } else if (type == ToolTypeZoom) {
        [self setSelectedTool:_zoomTool];
    }
}


#pragma mark - Accessors

- (void) setSelectedToolIndex:(NSInteger)selectedToolIndex
{
    @synchronized(self) {
        if (_selectedToolIndex != selectedToolIndex) {
            _selectedToolIndex = selectedToolIndex;
            _selectedTool = [[self allTools] objectAtIndex:selectedToolIndex];
            [self _updateInspector];
        }

    }
}


- (NSInteger) selectedToolIndex
{
    @synchronized(self) {
        return _selectedToolIndex;
    }
}


- (void) setSelectedTool:(Tool *)selectedTool
{
    @synchronized(self) {
        if (_selectedTool != selectedTool) {
            _selectedTool = selectedTool;
            _selectedToolIndex = [[self allTools] indexOfObject:selectedTool];
            [self _updateInspector];
        }
    }
}


- (Tool *) selectedTool
{
    @synchronized(self) {
        return _selectedTool;
    }
}


- (void) setSelectedObject:(CanvasObject *)selectedObject
{
    @synchronized(self) {
        if (_selectedObject != selectedObject) {
            _selectedObject = selectedObject;
            [self _updateInspector];
        }
    }
}


- (CanvasObject *) selectedObject
{
    @synchronized(self) {
        return _selectedObject;
    }
}

@end
