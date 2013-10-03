//
//  CursorAdditions.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "CursorAdditions.h"

@interface NSCursor (Private)
+ (id)_helpCursor;
+ (id)_windowResizeNorthWestSouthEastCursor;
+ (id)_windowResizeNorthEastSouthWestCursor;
+ (id)_windowResizeSouthWestCursor;
+ (id)_windowResizeSouthEastCursor;
+ (id)_windowResizeNorthWestCursor;
+ (id)_windowResizeNorthEastCursor;
+ (id)_windowResizeNorthSouthCursor;
+ (id)_windowResizeSouthCursor;
+ (id)_windowResizeNorthCursor;
+ (id)_windowResizeEastWestCursor;
+ (id)_windowResizeWestCursor;
+ (id)_windowResizeEastCursor;
+ (id)_zoomOutCursor;
+ (id)_zoomInCursor;
+ (id)_resizeLeftRightCursor;
+ (id)_resizeRightCursor;
+ (id)_resizeLeftCursor;
+ (id)_topRightResizeCursor;
+ (id)_bottomRightResizeCursor;
+ (id)_topLeftResizeCursor;
+ (id)_bottomLeftResizeCursor;
+ (id)_verticalResizeCursor;
+ (id)_horizontalResizeCursor;
+ (id)_crosshairCursor;
+ (id)_waitCursor;
+ (id)_moveCursor;
+ (id)_closedHandCursor;
+ (id)_handCursor;
+ (id)_genericDragCursor;
+ (id)dragLinkCursor;
+ (id)_copyDragCursor;
+ (id)dragCopyCursor;
+ (BOOL)helpCursorShown;
+ (id)_setHelpCursor:(BOOL)arg1;
+ (id)_makeCursors;
+ (void)pop;
+ (void)_clearOverrideCursorAndSetArrow;
+ (void)_setOverrideCursor:(id)arg1;
+ (id)currentSystemCursor;
+ (id)currentCursor;
+ (void)setHiddenUntilMouseMoves:(BOOL)arg1;
+ (void)unhide;
+ (void)hide;
+ (id)IBeamCursorForVerticalLayout;
+ (id)contextualMenuCursor;
+ (id)busyButClickableCursor;
+ (id)operationNotAllowedCursor;
+ (id)disappearingItemCursor;
+ (id)crosshairCursor;
+ (id)resizeUpDownCursor;
+ (id)resizeDownCursor;
+ (id)resizeUpCursor;
+ (id)resizeLeftRightCursor;
+ (id)resizeRightCursor;
+ (id)resizeLeftCursor;
+ (id)openHandCursor;
+ (id)closedHandCursor;
+ (id)pointingHandCursor;
+ (id)IBeamCursor;
+ (id)arrowCursor;
+ (id)_buildCursor:(id)arg1 cursorData:(struct CGPoint)arg2;
+ (void)initialize;
- (void)pop;
- (void)push;
- (id)awakeAfterUsingCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (void)mouseExited:(id)arg1;
- (void)mouseEntered:(id)arg1;
- (id)forceSet;
- (void)set;
- (void)_reallySet;
- (id)_premultipliedARGBBitmaps;
- (BOOL)isSetOnMouseEntered;
- (BOOL)isSetOnMouseExited;
- (void)setOnMouseEntered:(BOOL)arg1;
- (void)setOnMouseExited:(BOOL)arg1;
- (struct CGPoint)hotSpot;
- (id)image;
- (void)_getImageAndHotSpotFromCoreCursor;
- (long long)_coreCursorType;
- (void)dealloc;
- (id)init;
- (void)_setImage:(id)arg1;
- (id)initWithImage:(id)arg1 foregroundColorHint:(id)arg2 backgroundColorHint:(id)arg3 hotSpot:(struct CGPoint)arg4;
- (id)initWithImage:(id)arg1 hotSpot:(struct CGPoint)arg2;
@end

@implementation NSCursor (PixelWinch)

+ (NSCursor *) winch_resizeNorthWestSouthEastCursor
{
    return [self _windowResizeNorthWestSouthEastCursor];
}


+ (NSCursor *) winch_resizeNorthEastSouthWestCursor
{
    return [self _windowResizeNorthEastSouthWestCursor];
}

+ (NSCursor *) winch_resizeNorthSouthCursor
{
    return [self _windowResizeNorthSouthCursor];
}

+ (NSCursor *) winch_resizeEastWestCursor
{
    return [self _windowResizeEastWestCursor];
}


+ (NSCursor *) winch_zoomInCursor
{
    static NSCursor *sCursor = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sCursor) {
            NSImage *image = [NSImage imageNamed:@"cursor_zoom_in"];
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(0, 0)];
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
            sCursor = [[NSCursor alloc] initWithImage:image hotSpot:CGPointMake(0, 0)];
        }
    });

    return sCursor;
}

@end
