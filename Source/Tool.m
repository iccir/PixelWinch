//
//  Tool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "Tool.h"

@implementation Tool

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super init])) {
    
    }
    
    return self;
}


- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self writeToDictionary:dictionary];
    return dictionary;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary { }


- (NSCursor *) cursor
{
    return nil;
}


- (NSString *) name
{
    return nil;
}


- (unichar) shortcutKey
{
    return 0;
}


- (BOOL) canSelectCanvasObject:(CanvasObject *)object
{
    return NO;
}

- (void) reset { }
- (void) didSelect { }
- (void) didUnselect { }

- (void) canvasWindowDidAppear { }

- (void) flagsChangedWithEvent:(NSEvent *)event { }

- (void) mouseMovedWithEvent:(NSEvent *)event { }
- (void) mouseExitedWithEvent:(NSEvent *)event { }

- (BOOL) mouseDownWithEvent:(NSEvent *)event { return YES; }
- (void) mouseDraggedWithEvent:(NSEvent *)event { }
- (void) mouseUpWithEvent:(NSEvent *)event { }

@end
