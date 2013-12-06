//
//  IXWeakTargetActionPair.m
//  IXCore
//
//  Created by Ricci Adams on 2013-11-20.
//
//

#import "WeakTargetActionPair.h"


@implementation WeakTargetActionPair

+ (instancetype) pairWithTarget:(id)target action:(SEL)action
{
    WeakTargetActionPair *result = [[WeakTargetActionPair alloc] init];

    [result setTarget:target];
    [result setAction:action];
    
    return result;
}


- (BOOL) invokeWithSender:(id)sender
{
    // This was previously a non-nil target, but is now zero'd.  Return.
    if (!_target) return NO;

    NSMethodSignature *signature = [_target methodSignatureForSelector:_action];
    IMP imp = [_target methodForSelector:_action];

    const char *argument2  = ([signature numberOfArguments] > 2) ? ([signature getArgumentTypeAtIndex:2]) : NULL;
    const char *returnType = [signature methodReturnType];

    BOOL takesSender   = argument2  ? strcmp(argument2,  @encode(id)) == 0 : NO;
    BOOL returnsObject = returnType ? strcmp(returnType, @encode(id)) == 0 : NO;
    
    if (takesSender) {
        if (returnsObject) {
            id (*castedImp)(id, SEL, id) = (void *)imp;
            id result = castedImp(_target, _action, sender);
            (void)result;
        } else {
            void (*castedImp)(id, SEL, id) = (void *)imp;
            castedImp(_target, _action, sender);
        }

    } else {
        if (returnsObject) {
            id (*castedImp)(id, SEL) = (void *)imp;
            id result = castedImp(_target, _action);
            (void)result;
        } else {
            void (*castedImp)(id, SEL) = (void *)imp;
            castedImp(_target, _action);
        }
    }

    return YES;
}


@end
