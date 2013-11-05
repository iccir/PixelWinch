//
//  PurchaseManager.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-04.
//
//

#import <Foundation/Foundation.h>

#define ENABLE_APP_STORE 0

#if ENABLE_APP_STORE

@interface PurchaseManager : NSObject

+ (instancetype) sharedInstance;

- (void) purchasePaidVersion;
- (void) restorePurchases;

- (BOOL) doesReceiptExist;

@end

#endif
