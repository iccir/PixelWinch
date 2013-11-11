//
//  ScreenAdditions.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-05.
//
//

@interface NSScreen (PixelWinch)

+ (NSPoint) winch_convertPointFromGlobal:(CGPoint)globalPoint;
+ (CGPoint) winch_convertPointToGlobal:(NSPoint)appKitPoint;

+ (NSRect) winch_convertRectFromGlobal:(CGRect)globalRect;
+ (CGRect) winch_convertRectToGlobal:(NSRect)appKitRect;

+ (NSArray *) winch_screensWithGlobalPoint:(CGPoint)point;
+ (NSArray *) winch_screensWithGlobalRect:(CGRect)rect;
+ (instancetype) winch_screenWithGlobalRect:(CGRect)rect;

+ (instancetype) winch_screenWithCGDirectDisplayID:(CGDirectDisplayID)directDisplayID;

- (CGDirectDisplayID) winch_CGDirectDisplayID;

- (CGRect) winch_globalFrame;

- (NSString *) winch_name;

@end
