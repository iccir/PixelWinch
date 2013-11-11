//
//  MarqueeTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "MarqueeTool.h"
#import "Canvas.h"
#import "CanvasObjectView.h"
#import "Marquee.h"


@implementation MarqueeTool

- (NSCursor *) cursor
{
    return [NSCursor crosshairCursor];
}


- (NSString *) name
{
    return @"marquee";
}


- (unichar) shortcutKey
{
    return 'm';
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    Canvas *canvas = [[self owner] canvas];

    NSArray *objects = [canvas canvasObjectsWithGroupName:[Marquee groupName]];
    for (CanvasObject *object in objects) {
        [canvas removeCanvasObject:object];
    }

    Marquee *marquee = [[Marquee alloc] init];
    [canvas addCanvasObject:marquee];
    
    CanvasObjectView *view = [[self owner] viewForCanvasObject:marquee];
    [view trackWithEvent:event newborn:YES];

    return NO;
}


@end
