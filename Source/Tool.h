//
//  Tool.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import <Foundation/Foundation.h>

@class Tool, Canvas, CanvasView, CanvasObject, CanvasObjectView;


@protocol ToolOwner <NSObject>
- (Canvas *) canvas;
- (CanvasView *) canvasView;
- (CanvasObjectView *) viewForCanvasObject:(CanvasObject *)canvasObject;
- (void) zoomWithDirection:(NSInteger)direction event:(NSEvent *)event;
- (BOOL) isToolSelected:(Tool *)tool;
@end


@interface Tool : NSObject

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *) dictionaryRepresentation;

// Subclasses to override, must call super
- (void) writeToDictionary:(NSMutableDictionary *)dictionary;

- (BOOL) canSelectCanvasObject:(CanvasObject *)object;

@property (nonatomic, weak) id<ToolOwner> owner;

- (NSCursor *) cursor;
- (NSString *) name;
- (unichar) shortcutKey;

- (void) reset;
- (void) didUnselect;
- (void) didSelect;

- (void) flagsChangedWithEvent:(NSEvent *)event;

- (void) mouseMovedWithEvent:(NSEvent *)event;
- (void) mouseExitedWithEvent:(NSEvent *)event;

- (BOOL) mouseDownWithEvent:(NSEvent *)event;
- (void) mouseDraggedWithEvent:(NSEvent *)event;
- (void) mouseUpWithEvent:(NSEvent *)event;

@end
