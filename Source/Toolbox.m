//
//  Toolbox.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-23.
//
//

#import "Toolbox.h"

#import "MoveTool.h"
#import "HandTool.h"
#import "MarqueeTool.h"
#import "RectangleTool.h"
#import "GrappleTool.h"
#import "ZoomTool.h"

static NSString * const sToolsKey         = @"tools";
static NSString * const sSelectedKey      = @"selectedToolType";
static NSString * const sMoveToolKey      = @"move";
static NSString * const sHandToolKey      = @"hand";
static NSString * const sMarqueeToolKey   = @"marquee";
static NSString * const sRectangleToolKey = @"rectangle";
static NSString * const sGrappleToolKey   = @"grapple";
static NSString * const sZoomToolKey      = @"zoom";

@interface Toolbox ()
@property (nonatomic, strong) Tool *selectedTool;
@end




@implementation Toolbox {

}

@dynamic selectedToolIndex, selectedToolType;



+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;

    if ([key isEqualToString:@"selectedTool"]) {
        affectingKeys = @[ @"selectedToolIndex", @"selectedToolType" ];
    } else if ([key isEqualToString:@"selectedToolIndex"]) {
        affectingKeys = @[ @"selectedTool", @"selectedToolType" ];
    } else if ([key isEqualToString:@"selectedToolType"]) {
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
        _grappleTool   = [[GrappleTool   alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sGrappleToolKey]];
        _zoomTool      = [[ZoomTool      alloc] initWithDictionaryRepresentation:[dictionary objectForKey:sZoomToolKey]];

        ToolType selectedToolType = [[dictionary objectForKey:sSelectedKey] integerValue];
        [self setSelectedToolType:selectedToolType];
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
    write(_grappleTool,   sGrappleToolKey);
    write(_zoomTool,      sZoomToolKey);
    
    ToolType selectedToolType = [self selectedToolType];
    [state setObject:@(selectedToolType) forKey:sSelectedKey];

    [[NSUserDefaults standardUserDefaults] setObject:state forKey:sToolsKey];
}


- (NSArray *) allTools
{
    return @[ _moveTool, _handTool, _marqueeTool, _rectangleTool, _grappleTool, _zoomTool ];
}


- (void) setSelectedTool:(Tool *)tool
{
    if (_selectedTool != tool) {
        _selectedTool = tool;
        [self _writeState];
    }
}


- (void) setSelectedToolType:(ToolType)toolType
{
    Tool *selectedTool = nil;

    for (Tool *tool in [self allTools]) {
        if ([tool type] == toolType) {
            selectedTool = tool;
            break;
        }
    }
    
    if (selectedTool) {
        [self setSelectedTool:selectedTool];
    }
}


- (ToolType) selectedToolType
{
    return [_selectedTool type];
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
