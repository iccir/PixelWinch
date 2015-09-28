//
//  CanvasObject.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>

@class Canvas;

extern NSString * const PasteboardTypeCanvasObjects;

@interface CanvasObject : NSObject <NSPasteboardWriting>

+ (NSData *) pasteboardDataWithCanvasObjects:(NSArray<CanvasObject *> *)objects;
+ (NSArray<CanvasObject *> *) canvasObjectsWithPasteboardData:(NSData *)data;

+ (CanvasObject *) canvasObjectWithGroupName: (NSString *) groupName
                    dictionaryRepresentation: (NSDictionary *) dictionaryRepresentation;

+ (NSString *) groupName;  // Subclasses to override


@property (nonatomic, weak) Canvas *canvas;
@property (nonatomic, readonly, strong) NSString *GUID;
@property (nonatomic, readonly) NSTimeInterval timestamp;

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *) dictionaryRepresentation;

- (id) duplicate;

// Subclasses to override, must call super.  Return YES if dictionary is valid
- (BOOL) readFromDictionary:(NSDictionary *)dictionary;

// Subclasses to override, must call super
- (void) writeToDictionary:(NSMutableDictionary *)dictionary NS_REQUIRES_SUPER;

// Subclasses to call when modifying, for undo support
- (void) beginChanges;
- (void) endChanges;

- (void) prepareRelativeMove;
- (void) performRelativeMoveWithDeltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY;

@property (nonatomic, readonly) NSString *pasteboardString;

@property (nonatomic, readonly, getter=isValid) BOOL valid;
@property (nonatomic) BOOL participatesInUndo; // defaults to YES
@property (nonatomic, getter=isPersistent) BOOL persistent; // defaults to YES

@property (nonatomic, assign) CGRect rect;

@property (nonatomic, getter=isSelectable) BOOL selectable;

// For bindings
@property (nonatomic, assign) CGFloat originX;
@property (nonatomic, assign) CGFloat originY;
@property (nonatomic, assign) CGFloat sizeWidth;
@property (nonatomic, assign) CGFloat sizeHeight;

@end
