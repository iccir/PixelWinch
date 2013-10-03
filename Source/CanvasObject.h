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

- (void) moveEdge:(CGRectEdge)edge value:(CGFloat)value;

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *) dictionaryRepresentation;

@end
