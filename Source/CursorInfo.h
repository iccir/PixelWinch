// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@interface CursorInfo : NSObject


+ (instancetype) sharedInstance;

- (void) setText:(NSString *)text forKey:(NSString *)key;
- (NSString *) textForKey:(NSString *)key;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@end
