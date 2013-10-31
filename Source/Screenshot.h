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
@property (nonatomic, readonly) NSInteger bytesPerRow;

@property (nonatomic, assign, readonly) CGImageRef CGImage;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) size_t width;
@property (nonatomic, readonly) size_t height;


@end
