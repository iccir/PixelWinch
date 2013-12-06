//
//  IXWeakTargetActionPair.h
//  IXCore
//
//  Created by Ricci Adams on 2013-11-20.
//
//

#import <Foundation/Foundation.h>

@interface WeakTargetActionPair : NSObject

+ (instancetype) pairWithTarget:(id)target action:(SEL)action;

- (BOOL) invokeWithSender:(id)sender;

@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@end
