//
//  Rectangle.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Rectangle : CanvasObject
+ (instancetype) rectangle;

@property (nonatomic, assign) CGRect rect;
@end
