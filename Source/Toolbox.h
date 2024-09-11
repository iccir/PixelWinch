// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "Tool.h"

@class Tool, MoveTool, HandTool, MarqueeTool, RectangleTool, LineTool, GrappleTool, ZoomTool;

@interface Toolbox : NSObject

@property (nonatomic, readonly) NSArray       *allTools;
@property (nonatomic, readonly) MoveTool      *moveTool;
@property (nonatomic, readonly) HandTool      *handTool;
@property (nonatomic, readonly) MarqueeTool   *marqueeTool;
@property (nonatomic, readonly) RectangleTool *rectangleTool;
@property (nonatomic, readonly) LineTool      *lineTool;
@property (nonatomic, readonly) GrappleTool   *grappleTool;
@property (nonatomic, readonly) ZoomTool      *zoomTool;

@property (nonatomic, readonly) Tool *selectedTool;
@property (nonatomic) NSInteger selectedToolIndex;
@property (nonatomic) NSString *selectedToolName;

- (void) beginTemporaryMode;
- (void) updateTemporaryMode;
- (void) endTemporaryMode;
@property (nonatomic, readonly, getter=isInTemporaryMode) BOOL inTemporaryMode;

@end
