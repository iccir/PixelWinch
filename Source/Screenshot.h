// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@interface Screenshot : NSObject

+ (void) clearCache;

+ (instancetype) screenshotWithContentsOfFile:(NSString *)path;

@property (nonatomic, readonly) CGImageRef CGImage;
@property (nonatomic, readonly, getter=isOpaque) BOOL opaque;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) size_t width;
@property (nonatomic, readonly) size_t height;

@end
