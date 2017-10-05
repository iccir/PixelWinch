//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "Application.h"

NSString * const SpaceBarWillGoUpNotificationName = @"SpaceBarWillGoUpNotification";

@implementation Application

- (void) sendEvent:(NSEvent *)event
{
    NSString *selectorName = nil;

    if ([event type] == NSEventTypeKeyUp) {
        if ([[event charactersIgnoringModifiers] isEqualToString:@" "]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SpaceBarWillGoUpNotificationName object:nil];
        }
    }

    if ([event type] == NSEventTypeKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
        NSString *characters = [event charactersIgnoringModifiers];

        if (modifierFlags == NSEventModifierFlagCommand) {
            selectorName = [@{
                @"c": @"copy:",
                @"v": @"paste:",
                @"x": @"cut:",
                @"z": @"undo:",
                @"a": @"selectAll:",
                @"w": @"performClose:",
                @"m": @"performMiniaturize:"
            } objectForKey:characters];

        } else if (modifierFlags == (NSEventModifierFlagCommand | NSEventModifierFlagShift)) {
            selectorName = [@{
                @"Z": @"redo:"
            } objectForKey:characters];
        }
    }
    
    if (selectorName) {
        SEL aSel = NSSelectorFromString(selectorName);

        if ([self sendAction:aSel to:nil from:self]) {
            return;
        }
    }

    if (IsInDebugger()) {
        [super sendEvent:event];

    } else {
        @try {
            [super sendEvent:event];
        } @catch (NSException *exception) {
            (NSGetUncaughtExceptionHandler())(exception);
        }
    }
}


@end
