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

@property (assign) CGRect rect;

// For bindings
@property (assign) CGFloat originX;
@property (assign) CGFloat originY;
@property (assign) CGFloat sizeWidth;
@property (assign) CGFloat sizeHeight;

@end
