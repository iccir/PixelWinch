//
//  Application.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-24.
//
//

#import "Application.h"

@implementation Application

- (void) sendEvent:(NSEvent *)event
{
    NSString *selectorName = nil;

	if ([event type] == NSKeyDown) {
        NSUInteger modifierFlags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
        NSString *characters = [event charactersIgnoringModifiers];

		if (modifierFlags == NSCommandKeyMask) {
            selectorName = [@{
                @"c": @"copy:",
                @"v": @"paste:",
                @"x": @"cut:",
                @"z": @"undo:",
                @"a": @"selectAll:",
                @"w": @"performClose:",
                @"m": @"performMiniaturize:"
            } objectForKey:characters];

        } else if (modifierFlags == (NSCommandKeyMask | NSShiftKeyMask)) {
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

	[super sendEvent:event];
}


@end
