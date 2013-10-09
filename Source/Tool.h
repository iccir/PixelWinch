//
//  Tool.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ToolType) {
    ToolTypeMove,
    ToolTypeHand,
    ToolTypeMarquee,
    ToolTypeRectangle,
    ToolTypeGrapple,
    ToolTypeZoom
};


@interface Tool : NSObject

- (NSCursor *) cursor;
@property (readonly) ToolType type;
@end
