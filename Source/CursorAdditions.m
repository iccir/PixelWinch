//
//  CursorAdditions.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "CursorAdditions.h"

#define DUMP_SYSTEM_CURSORS 0

@implementation NSCursor (PixelWinch)

#if DUMP_SYSTEM_CURSORS

+ (void) initialize
{
    NSArray *array = @[
        @"_helpCursor"
        , @"_windowResizeNorthWestSouthEastCursor"
        , @"_windowResizeNorthEastSouthWestCursor"
        , @"_windowResizeSouthWestCursor"
        , @"_windowResizeSouthEastCursor"
        , @"_windowResizeNorthWestCursor"
        , @"_windowResizeNorthEastCursor"
        , @"_windowResizeNorthSouthCursor"
        , @"_windowResizeSouthCursor"
        , @"_windowResizeNorthCursor"
        , @"_windowResizeEastWestCursor"
        , @"_windowResizeWestCursor"
        , @"_windowResizeEastCursor"
        , @"_zoomOutCursor"
        , @"_zoomInCursor"
        , @"_resizeLeftRightCursor"
        , @"_resizeRightCursor"
        , @"_resizeLeftCursor"
        , @"_topRightResizeCursor"
        , @"_bottomRightResizeCursor"
        , @"_topLeftResizeCursor"
        , @"_bottomLeftResizeCursor"
        , @"_verticalResizeCursor"
        , @"_horizontalResizeCursor"
        , @"_crosshairCursor"
        , @"_waitCursor"
        , @"_moveCursor"
        , @"_closedHandCursor"
        , @"_handCursor"
        , @"_genericDragCursor"
        , @"dragLinkCursor"
        , @"_copyDragCursor"
        , @"dragCopyCursor"
        , @"IBeamCursorForVerticalLayout"
        , @"contextualMenuCursor"
        , @"busyButClickableCursor"
        , @"operationNotAllowedCursor"
        , @"disappearingItemCursor"
        , @"crosshairCursor"
        , @"resizeUpDownCursor"
        , @"resizeDownCursor"
        , @"resizeUpCursor"
        , @"resizeLeftRightCursor"
        , @"resizeRightCursor"
        , @"resizeLeftCursor"
        , @"openHandCursor"
        , @"closedHandCursor"
        , @"pointingHandCursor"
        , @"IBeamCursor"
        , @"arrowCursor"
    ];

    for (NSString *name in array) {
        NSCursor *cursor = [NSCursor performSelector:NSSelectorFromString(name)];
        
        NSLog(@"%@, %@", name, NSStringFromPoint([cursor hotSpot]));
        
        for (NSImageRep *rep in [[cursor image] representations]) {
            NSString *path = NSTemporaryDirectory();
            NSInteger width = [rep pixelsWide];
            NSInteger height = [rep pixelsHigh];

            NSString *filename = [NSString stringWithFormat:@"%@_%ld_%ld.tiff", name, (long)width, (long)height];
            
            path = [path stringByAppendingPathComponent:filename];
            
            [[(NSBitmapImageRep *)rep TIFFRepresentation] writeToFile:path atomically:YES];
        }
    }
    
    NSLog(@"%@", NSTemporaryDirectory());
}

#endif


+ (NSCursor *) winch_grappleHorizontalCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_grapple_h"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(12, 12)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_grappleVerticalCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_grapple_v"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(12, 12)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_resizeNorthWestSouthEastCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_resize_nw_se"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(9, 9)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_resizeNorthEastSouthWestCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_resize_ne_sw"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(9, 9)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_resizeNorthSouthCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_resize_n_s"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(9, 9)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_resizeEastWestCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_resize_w_e"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(9, 9)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_zoomInCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_zoom_in"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(8, 7)];
        }
    });

    return sCursor;
}


+ (NSCursor *) winch_zoomOutCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_zoom_out"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(8, 7)];
        }
    });

    return sCursor;
}


@end
