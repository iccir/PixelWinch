//
//  Screenshot.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-13.
//
//

#import <Foundation/Foundation.h>

@interface Screenshot : NSObject

+ (void) clearCache;

+ (instancetype) screenshotWithContentsOfFile:(NSString *)path;

@property (nonatomic, readonly) CGImageRef CGImage;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) size_t width;
@property (nonatomic, readonly) size_t height;

@end
