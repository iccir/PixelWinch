//
//  CursorAdditions.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>

@interface NSCursor (PixelWinch)

+ (NSCursor *) winch_zoomInCursor;
+ (NSCursor *) winch_zoomOutCursor;

+ (NSCursor *) winch_resizeNorthWestSouthEastCursor;
+ (NSCursor *) winch_resizeNorthEastSouthWestCursor;
+ (NSCursor *) winch_resizeNorthSouthCursor;
+ (NSCursor *) winch_resizeEastWestCursor;


@end
