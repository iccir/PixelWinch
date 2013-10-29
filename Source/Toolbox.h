//
//  Toolbox.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-23.
//
//

#import <Foundation/Foundation.h>
#import "Tool.h"

@class Tool, MoveTool, HandTool, MarqueeTool, RectangleTool, GrappleTool, ZoomTool;

@interface Toolbox : NSObject

@property (nonatomic, readonly) NSArray       *allTools;
@property (nonatomic, readonly) MoveTool      *moveTool;
@property (nonatomic, readonly) HandTool      *handTool;
@property (nonatomic, readonly) MarqueeTool   *marqueeTool;
@property (nonatomic, readonly) RectangleTool *rectangleTool;
@property (nonatomic, readonly) GrappleTool   *grappleTool;
@property (nonatomic, readonly) ZoomTool      *zoomTool;

@property (nonatomic, readonly) Tool *selectedTool;
@property (nonatomic) NSInteger selectedToolIndex;
@property (nonatomic) ToolType selectedToolType;

@end
