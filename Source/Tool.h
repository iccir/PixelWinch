// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
- (void) didDeselect;
- (void) didSelect;

- (void) canvasWindowDidAppear;
- (void) canvasWindowDidResign;

- (void) flagsChangedWithEvent:(NSEvent *)event;

- (void) mouseMovedWithEvent:(NSEvent *)event;
- (void) mouseExitedWithEvent:(NSEvent *)event;

- (BOOL) mouseDownWithEvent:(NSEvent *)event;
- (void) mouseDraggedWithEvent:(NSEvent *)event;
- (void) mouseUpWithEvent:(NSEvent *)event;

@end
