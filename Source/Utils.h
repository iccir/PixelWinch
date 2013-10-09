//
//  Utils.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import <Foundation/Foundation.h>

extern NSTimer *MakeWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats);
extern NSTimer *MakeScheduledWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats);

extern NSImage *GetSnapshotImageForView(NSView *view);

extern CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale);
extern CGImageRef   CreateImageMask(CGSize size, CGFloat scale, void (^callback)(CGContextRef));
extern CGImageRef   CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef));


extern CGImageRef CopyImageNamed(NSString *name);

extern CGRect GetRectByAdjustingEdge(CGRect rect, CGRectEdge edge, CGFloat value);

extern void WithWhiteOnBlackTextMode(void (^callback)());
