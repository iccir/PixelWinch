//
//  CanvasObject.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>

@class Canvas;

@interface CanvasObject : NSObject
@property (nonatomic, weak) Canvas *canvas;
@property (nonatomic, readonly, strong) NSString *GUID;

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *) dictionaryRepresentation;

// Subclasses to override, must call super.  Return YES if dictionary is valid
- (BOOL) readFromDictionary:(NSDictionary *)dictionary;

// Subclasses to override, must call super
- (void) writeToDictionary:(NSMutableDictionary *)dictionary;

// Subclasses to call when modifying, for undo support
- (void) beginChanges;
- (void) endChanges;

@property (nonatomic, readonly) BOOL isValid;

@property (nonatomic, assign) CGRect rect;

// For bindings
@property (nonatomic, assign) CGFloat originX;
@property (nonatomic, assign) CGFloat originY;
@property (nonatomic, assign) CGFloat sizeWidth;
@property (nonatomic, assign) CGFloat sizeHeight;

@end
