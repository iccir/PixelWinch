//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "RectangleTool.h"
#import "Canvas.h"
#import "Rectangle.h"
#import "CanvasObjectView.h"


@implementation RectangleTool

- (NSCursor *) cursor
{
    return [NSCursor crosshairCursor];
}


- (NSString *) name
{
    return @"rectangle";
}


- (unichar) shortcutKey
{
    return 'r';
}


- (BOOL) canSelectCanvasObject:(CanvasObject *)object
{
    return [object isKindOfClass:[Rectangle class]];
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    Rectangle *rectangle = [Rectangle rectangle];
    [[[self owner] canvas] addCanvasObject:rectangle];

    CanvasObjectView *view = [[self owner] viewForCanvasObject:rectangle];
   
    [view trackWithEvent:event newborn:YES];

    return NO;
}


@end
