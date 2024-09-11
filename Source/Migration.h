// (c) 2023-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Migration : NSObject

+ (BOOL) needsMigration;
+ (void) migrate;

+ (BOOL) isValidReceiptData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
