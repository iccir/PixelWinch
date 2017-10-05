//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@interface NSCursor (PixelWinch)

+ (NSCursor *) winch_wandCursor;

+ (NSCursor *) winch_zoomInCursor;
+ (NSCursor *) winch_zoomOutCursor;

+ (NSCursor *) winch_grappleHorizontalCursor;
+ (NSCursor *) winch_grappleVerticalCursor;

+ (NSCursor *) winch_resizeNorthWestSouthEastCursor;
+ (NSCursor *) winch_resizeNorthEastSouthWestCursor;
+ (NSCursor *) winch_resizeNorthSouthCursor;
+ (NSCursor *) winch_resizeEastWestCursor;


@end
