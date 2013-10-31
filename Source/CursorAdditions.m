//
//  CursorAdditions.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "CursorAdditions.h"

#ifdef DEBUG

static NSMutableDictionary *sTypeToNameMap      = nil;
static NSMutableDictionary *sInstancesToNameMap = nil;


@interface NSCursor (Private)
- (long long) _coreCursorType;
@end

#endif

#define DUMP_SYSTEM_CURSORS 0
#define DEBUG_CURSORS 0

@implementation NSCursor (PixelWinch)

#if DEBUG_CURSORS
#ifdef DEBUG


+ (void) initialize
{
    NSArray *array = @[
        @"_helpCursor",
        @"_windowResizeNorthWestSouthEastCursor",
        @"_windowResizeNorthEastSouthWestCursor",
        @"_windowResizeSouthWestCursor",
        @"_windowResizeSouthEastCursor",
        @"_windowResizeNorthWestCursor",
        @"_windowResizeNorthEastCursor",
        @"_windowResizeNorthSouthCursor",
        @"_windowResizeSouthCursor",
        @"_windowResizeNorthCursor",
        @"_windowResizeEastWestCursor",
        @"_windowResizeWestCursor",
        @"_windowResizeEastCursor",
        @"_zoomOutCursor",
        @"_zoomInCursor",
        @"_resizeLeftRightCursor",
        @"_resizeRightCursor",
        @"_resizeLeftCursor",
        @"_topRightResizeCursor",
        @"_bottomRightResizeCursor",
        @"_topLeftResizeCursor",
        @"_bottomLeftResizeCursor",
        @"_verticalResizeCursor",
        @"_horizontalResizeCursor",
        @"_crosshairCursor",
        @"_waitCursor",
        @"_moveCursor",
        @"_closedHandCursor",
        @"_handCursor",
        @"_genericDragCursor",
        @"dragLinkCursor",
        @"_copyDragCursor",
        @"dragCopyCursor",
        @"IBeamCursorForVerticalLayout",
        @"contextualMenuCursor",
        @"busyButClickableCursor",
        @"operationNotAllowedCursor",
        @"disappearingItemCursor",
        @"crosshairCursor",
        @"resizeUpDownCursor",
        @"resizeDownCursor",
        @"resizeUpCursor",
        @"resizeLeftRightCursor",
        @"resizeRightCursor",
        @"resizeLeftCursor",
        @"openHandCursor",
        @"closedHandCursor",
        @"pointingHandCursor",
        @"IBeamCursor",
        @"arrowCursor"
    ];

    if (!sTypeToNameMap)      sTypeToNameMap      = [NSMutableDictionary dictionary];
    if (!sInstancesToNameMap) sInstancesToNameMap = [NSMutableDictionary dictionary];

    for (NSString *name in array) {
        NSCursor *cursor = [NSCursor performSelector:NSSelectorFromString(name)];
        [sTypeToNameMap setObject:name forKey:@( [cursor _coreCursorType] )];
    }

    array = @[
        @"winch_zoomInCursor",
        @"winch_zoomOutCursor",
        @"winch_grappleHorizontalCursor",
        @"winch_grappleVerticalCursor",
        @"winch_resizeNorthWestSouthEastCursor",
        @"winch_resizeNorthEastSouthWestCursor",
        @"winch_resizeNorthSouthCursor",
        @"winch_resizeEastWestCursor"
    ];

    for (NSString *name in array) {
        NSCursor *cursor = [NSCursor performSelector:NSSelectorFromString(name)];
        [sInstancesToNameMap setObject:name forKey:[NSValue valueWithPointer:(__bridge void *)cursor]];
    }
    
    XUISwizzleMethod([NSCursor class], '-', @selector(set), @selector(debug_set));
}


- (void) debug_set
{
    static NSInteger sDidZoomIn = 0;

    if ((sDidZoomIn > 10) && (self == [NSCursor arrowCursor])) {
        NSLog(@"SETTING ARROW after zoom in");
    }

    if (self == [NSCursor winch_zoomInCursor]) {
        sDidZoomIn++;
    }

    NSLog(@"Setting %@", self);
    [self debug_set];
}

- (NSString *) description
{
    NSString *name = [sInstancesToNameMap objectForKey:[NSValue valueWithPointer:(__bridge void *)self]];
    if (!name) name = [sTypeToNameMap objectForKey:@([self _coreCursorType])];
    if (!name) name = @"unknown";
    
    return [NSString stringWithFormat:@"[NSCursor %@", name];
}

#endif
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
