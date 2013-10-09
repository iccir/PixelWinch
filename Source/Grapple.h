//
//  Grapple.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Grapple : CanvasObject

+ (instancetype) grappleVertical:(BOOL)vertical;

@property (nonatomic, readonly, getter=isVertical) BOOL vertical;

@end
