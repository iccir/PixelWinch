//
//  Screenshot.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-13.
//
//

#import <Foundation/Foundation.h>

@interface Screenshot : NSObject

+ (instancetype) screenshotWithContentsOfFile:(NSString *)path;

- (UInt8 *) RGBData NS_RETURNS_INNER_POINTER;
- (UInt8 *) RGBAData NS_RETURNS_INNER_POINTER;
@property (readonly) NSInteger bytesPerRow;

@property (assign, readonly) CGImageRef CGImage;

@property (readonly) CGSize size;
@property (readonly) size_t width;
@property (readonly) size_t height;


@end
