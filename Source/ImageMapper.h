//
//  ImageMapper.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-11.
//
//

#import <Foundation/Foundation.h>

@class Screenshot;

extern NSString * const ImageMapperDidBuildMapsNotification;

@interface ImageMapper : NSObject

- (id) initWithScreenshot:(Screenshot *)screenshot;

- (void) buildMaps;
- (BOOL) isReady;

- (UInt8 *) horizontalMap NS_RETURNS_INNER_POINTER;
- (UInt8 *) verticalMap   NS_RETURNS_INNER_POINTER;

@end
