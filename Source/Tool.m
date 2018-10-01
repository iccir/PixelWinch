//  (c) 2013-2018, Ricci Adams.  All rights reserved.


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
- (void) didDeselect { }

- (void) canvasWindowDidAppear { }
- (void) canvasWindowDidResign { }

- (void) flagsChangedWithEvent:(NSEvent *)event { }

- (void) mouseMovedWithEvent:(NSEvent *)event { }
- (void) mouseExitedWithEvent:(NSEvent *)event { }

- (BOOL) mouseDownWithEvent:(NSEvent *)event { return YES; }
- (void) mouseDraggedWithEvent:(NSEvent *)event { }
- (void) mouseUpWithEvent:(NSEvent *)event { }

@end
