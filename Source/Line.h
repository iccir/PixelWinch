//
//  Grapple.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Line : CanvasObject

+ (instancetype) lineVertical:(BOOL)vertical;

- (CGFloat) length;

@property (nonatomic, readonly, getter=isVertical) BOOL vertical;
@property (nonatomic, getter=isPreview) BOOL preview;

@end
