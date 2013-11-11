//
//  Toolbox.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-23.
//
//

#import "Toolbox.h"

#import "HandTool.h"
#import "LineTool.h"
#import "MarqueeTool.h"
#import "MoveTool.h"
#import "RectangleTool.h"
#import "GrappleTool.h"
#import "ZoomTool.h"

static NSString * const sToolsKey         = @"tools";
static NSString * const sSelectedKey      = @"selectedToolName";
static NSString * const sMoveToolKey      = @"move";
static NSString * const sHandToolKey      = @"hand";
static NSString * const sMarqueeToolKey   = @"marquee";
static NSString * const sRectangleToolKey = @"rectangle";
static NSString * const sLineToolKey      = @"line";
static NSString * const sGrappleToolKey   = @"grapple";
static NSString * const sZoomToolKey      = @"zoom";

@interface Toolbox ()
@property (nonatomic, strong) Tool *selectedTool;
@end




@implementation Toolbox {
    NSArray *_allTools;
}

@dynamic selectedToolIndex, selectedToolName;



+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;

    if ([key isEqualToString:@"selectedTool"]) {
        affectingKeys = @[ @"selectedToolIndex", @"selectedToolName" ];
    } else if ([key isEqualToString:@"selectedToolIndex"]) {
        affectingKeys = @[ @"selectedTool", @"selectedToolName" ];
    } else if ([key isEqualToString:@"selectedToolName"]) {
        affectingKeys = @[ @"selectedTool", @"selectedToolIndex" ];
    }
    
    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    
    return keyPaths;
}


- (id) init
{
    if ((self = [super init])) {
        NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:sToolsKey];
    
        _moveTool      = [[MoveTool      alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sMoveToolKey]];
        _handTool      = [[HandTool      alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sHandToolKey]];
        _marqueeTool   = [[MarqueeTool   alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sMarqueeToolKey]];
        _rectangleTool = [[RectangleTool alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sRectangleToolKey]];
        _lineTool      = [[LineTool      alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sLineToolKey]];
        _grappleTool   = [[GrappleTool   alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sGrappleToolKey]];
        _zoomTool      = [[ZoomTool      alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sZoomToolKey]];

        NSString *selectedToolName = [dictionary objectForKey:sSelectedKey];
        [self setSelectedToolName:selectedToolName];
    }
    
    return self;
}


- (void) _writeState
{
    NSMutableDictionary *state = [NSMutableDictionary dictionary];
    
    void (^write)(Tool *, NSString *) = ^(Tool *tool, NSString *key) {
        NSDictionary *dictionary = [tool dictionaryRepresentation];

        if ([dictionary count]) {
            [state setObject:dictionary forKey:key];
        }
    };
    
    write(_moveTool,      sMoveToolKey);
    write(_handTool,      sHandToolKey);
    write(_marqueeTool,   sMarqueeToolKey);
    write(_rectangleTool, sRectangleToolKey);
    write(_lineTool,      sLineToolKey);
    write(_zoomTool,      sZoomToolKey);
    
    if (_grappleTool) {
        write((Tool *)_grappleTool, sGrappleToolKey);
    }
    
    NSString *selectedToolName = [self selectedToolName];
    if (selectedToolName) [state setObject:selectedToolName forKey:sSelectedKey];

    [[NSUserDefaults standardUserDefaults] setObject:state forKey:sToolsKey];
}


- (NSArray *) allTools
{
    if (!_allTools) {
        _allTools = @[ _moveTool, _handTool, _marqueeTool, _rectangleTool, _lineTool, _grappleTool, _zoomTool ];

        if (![GrappleTool isEnabled]) {
            NSMutableArray *allTools = [_allTools mutableCopy];
            [allTools removeObject:_grappleTool];
            _allTools = allTools;
        }
    }

    return _allTools;
}


- (void) setSelectedTool:(Tool *)tool
{
    if (_selectedTool != tool) {
        Tool *oldTool = _selectedTool;
        _selectedTool = tool;

        [oldTool didUnselect];
        [_selectedTool didSelect];

        [self _writeState];
    }
}


- (void) setSelectedToolName:(NSString *)name
{
    Tool *selectedTool = nil;

    for (Tool *tool in [self allTools]) {
        if ([name isEqualToString:[tool name]]) {
            selectedTool = tool;
            break;
        }
    }
    
    if (selectedTool) {
        [self setSelectedTool:selectedTool];
    }
}


- (NSString *) selectedToolName
{
    return [_selectedTool name];
}


- (void) setSelectedToolIndex:(NSInteger)selectedToolIndex
{
    Tool *tool = [[self allTools] objectAtIndex:selectedToolIndex];
    [self setSelectedTool:tool];
}


- (NSInteger) selectedToolIndex
{
    return [[self allTools] indexOfObject:_selectedTool];
}


@end
