//
//  PurchaseManager.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-04.
//
//

#import "PurchaseManager.h"
#import <StoreKit/StoreKit.h>

#define kPurchaseManagerPaidVersionProductID @"com.pixelwinch.PixelWinch.Instant"

#if ENABLE_APP_STORE

@interface PurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation PurchaseManager {
    NSMutableArray *_requests;
    SKProduct *_product;
}


+ (instancetype) sharedInstance
{
    static PurchaseManager *sSharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sSharedInstance = [[PurchaseManager alloc] init];
    });
    
    return sSharedInstance;
}


- (id) init
{
    if ((self = [super init])) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        _requests = [NSMutableArray array];

        [self requestProduct];
    }
    
    return self;
}


- (void) dealloc
{
    for (SKProductsRequest *request in _requests) {
        [request setDelegate:nil];
    }
}


- (void) requestProduct
{
    NSSet *productIdentifiers = [NSSet setWithArray:@[ kPurchaseManagerPaidVersionProductID ]];

    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    [request setDelegate:self];
    [_requests addObject:request];
}


- (BOOL) doesReceiptExist
{
    NSURL *url = [[NSBundle mainBundle] appStoreReceiptURL];
    return [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
}


- (void) purchasePaidVersion
{
    SKPayment *payment = [SKPayment paymentWithProduct:_product];
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


- (void) restorePurchases
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in [response products]) {
        if ([[product productIdentifier] isEqualToString:kPurchaseManagerPaidVersionProductID]) {
            _product = product;
            break;
        }
    }
    
    [request setDelegate:nil];
    [_requests removeObject:request];
}


- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{

    for (SKPaymentTransaction *transaction in transactions) {
        SKPaymentTransactionState state = [transaction transactionState];
        
        if (state == SKPaymentTransactionStatePurchasing) {
        
        } else if (state == SKPaymentTransactionStatePurchased) {
            // Notify?
            [queue finishTransaction:transaction];

        } else if (state == SKPaymentTransactionStateRestored) {
            // [transaction originalTransaction];
            [queue finishTransaction:transaction];

        } else if (state == SKPaymentTransactionStateFailed) {
            if ([[transaction error] code] != SKErrorPaymentCancelled) {
                // Display error?
            }

            [queue finishTransaction:transaction];
        }
    }
}


- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{

}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{

}


@end

#endif