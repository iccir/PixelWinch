//
//  Migration.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2023-02-03.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Migration : NSObject

+ (void) migrateIfNeeded;

@end

NS_ASSUME_NONNULL_END
