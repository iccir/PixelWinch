//
//  TextLayer.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-10.
//
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, TextLayerStyle) {
    TextLayerStyleBoth = 0,
    TextLayerStyleWidthOnly,
    TextLayerStyleHeightOnly
};

@interface TextLayer : CALayer

@property CGSize dimensions;
@property TextLayerStyle textLayerStyle;

@end
