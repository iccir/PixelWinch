//
//  ImageMapper.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-11.
//
//

#import <Foundation/Foundation.h>

extern NSString * const ImageDistanceMapReadyNotificationName;

@interface ImageDistanceMap : NSObject

- (id) initWithCGImage:(CGImageRef)image;

- (void) buildMaps;

- (void) dump;

- (size_t) width;
- (size_t) height;

- (UInt8 *) horizontalPlane NS_RETURNS_INNER_POINTER;
- (UInt8 *) verticalPlane   NS_RETURNS_INNER_POINTER;

@end
