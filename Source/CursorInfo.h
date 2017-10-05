//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@interface CursorInfo : NSObject


+ (instancetype) sharedInstance;

- (void) setText:(NSString *)text forKey:(NSString *)key;
- (NSString *) textForKey:(NSString *)key;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@end
