//
//  CursorInfo.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-13.
//
//

#import <Foundation/Foundation.h>

@interface CursorInfo : NSObject


+ (instancetype) sharedInstance;

- (void) setText:(NSString *)text forKey:(NSString *)key;
- (NSString *) textForKey:(NSString *)key;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@end
