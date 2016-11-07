//
//  Utils.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//


extern NSString * const WinchFeedbackURLString;
extern NSString * const WinchWebsiteURLString;
extern NSString * const WinchGuideURLString;
extern NSString * const WinchAppStoreURLString;


// InvalidReceiptDelta will show up in a dissassembler as "kMeasurementScaleMode"
#define InvalidReceiptDelta kMeasurementScaleMode
extern CGFloat InvalidReceiptDelta;

#define NSStringFromCGPoint(P) NSStringFromPoint(NSPointFromCGPoint(P))
#define NSStringFromCGSize(S)  NSStringFromSize(NSSizeFromCGSize(S))
#define NSStringFromCGRect(R)  NSStringFromRect(NSRectFromCGRect(R))

static inline CGFLOAT_TYPE ScaleRound(CGFLOAT_TYPE x, CGFLOAT_TYPE scaleFactor)
{
    return round(x * scaleFactor) / scaleFactor;
}

static inline CGFLOAT_TYPE ScaleFloor(CGFLOAT_TYPE x, CGFLOAT_TYPE scaleFactor)
{
    return floor(x * scaleFactor) / scaleFactor;
}

static inline CGFLOAT_TYPE ScaleCeil( CGFLOAT_TYPE x, CGFLOAT_TYPE scaleFactor)
{
    return ceil( x * scaleFactor) / scaleFactor;
}

extern BOOL WinchSwizzleMethod(Class cls, char plusOrMinus, SEL selA, SEL selB);
extern BOOL WinchAliasMethod(Class cls, char plusOrMinus, SEL originalSel, SEL aliasSel);

extern CGContextRef GetCurrentGraphicsContext(void);
extern void PushGraphicsContext(CGContextRef context);
extern void PopGraphicsContext(void);

extern void WinchLog(NSString *category,  NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
extern void WinchWarn(NSString *category, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

extern BOOL IsInDebugger(void);

extern CGSize GetMaxThumbnailSize(void);

extern NSString *GetPixelWinchFeedbackURLString(void);
extern NSString *GetPixelWinchWebsiteURLString(void);
extern NSString *GetPixelWinchGuideURLString(void);
extern NSString *GetPixelWinchOnAppStoreURLString(void);

extern NSArray *GetClassesMatchesProtocol(Protocol *p);

extern NSColor *GetRGBColor(int rgb, CGFloat alpha);
extern NSColor *GetDarkWindowColor(void);

extern NSString *GetApplicationSupportDirectory(void);
extern NSString *GetScreenshotsDirectory(void);
extern NSString *MakeUniqueDirectory(NSString *path);

extern NSTimer *MakeWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats);
extern NSTimer *MakeScheduledWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats);

extern NSImage *GetSnapshotImageForView(NSView *view);


extern CGPathRef CopyPathWithBezierPath(NSBezierPath *path) CF_RETURNS_RETAINED;

extern CGRect EdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets);
extern NSImage *MakeImageWithCGImage(CGImageRef cgImage, CGFloat scale);

extern CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale);
extern CGImageRef   CreateImageMask(CGSize size, CGFloat scale, void (^callback)(CGContextRef));
extern CGImageRef   CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef));

extern void DrawImageAtPoint(NSImage *image, CGPoint point);
extern void DrawThreePart(NSImage *image, CGRect rect, CGFloat leftCap, CGFloat rightCap);

extern void ClipToImage(NSImage *image, CGRect rect);


extern CGImageRef CopyImageNamed(NSString *name);

extern CGFloat GetEdgeValueOfRect(CGRect rect, CGRectEdge edge);
extern CGRect GetRectByAdjustingEdge(CGRect rect, CGRectEdge edge, CGFloat value);

extern CGFloat GetDistance(CGPoint p1, CGPoint p2);

extern CGPoint GetFurthestCornerInRect(CGRect rect, CGPoint point);


extern void FillPathWithInnerShadow(NSBezierPath *path, NSShadow *shadow);

extern NSShadow *GetWhiteOnBlackTextShadow(void);
extern void WithWhiteOnBlackTextMode(void (^callback)());

extern void AddPopInAnimation(CALayer *layer, CGFloat duration);

extern NSString *GetStringForFloat(CGFloat f);
extern NSString *GetDisplayStringForSize(CGSize size);
extern NSString *GetPasteboardStringForSize(CGSize size);
