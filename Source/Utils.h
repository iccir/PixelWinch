//  (c) 2013-2018, Ricci Adams.  All rights reserved.


extern NSString * const WinchFeedbackURLString;
extern NSString * const WinchWebsiteURLString;
extern NSString * const WinchGuideURLString;
extern NSString * const WinchPrivacyURLString;


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

extern void PushGraphicsContext(CGContextRef context);
extern void PopGraphicsContext(void);

extern void WinchLog(NSString *category,  NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
extern void WinchWarn(NSString *category, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

extern BOOL IsInDebugger(void);

extern CGSize GetMaxThumbnailSize(void);

extern NSArray *GetClassesMatchesProtocol(Protocol *p);

extern NSColor *GetRGBColor(int rgb, CGFloat alpha);

extern NSString *GetApplicationSupportDirectory(void);
extern NSString *GetScreenshotsDirectory(void);
extern NSString *MakeUniqueDirectory(NSString *path);

extern NSTimer *MakeWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats);
extern NSTimer *MakeScheduledWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats);


extern CGRect EdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets);

extern CGImageRef CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef));


extern CGImageRef CopyImageNamed(NSString *name);

extern CGFloat GetEdgeValueOfRect(CGRect rect, CGRectEdge edge);
extern CGRect GetRectByAdjustingEdge(CGRect rect, CGRectEdge edge, CGFloat value);

extern CGFloat GetDistance(CGPoint p1, CGPoint p2);

extern CGPoint GetFurthestCornerInRect(CGRect rect, CGPoint point);

extern void AddPopInAnimation(CALayer *layer, CGFloat duration);

extern NSString *GetStringForFloat(CGFloat f);
extern NSString *GetDisplayStringForSize(CGSize size);
extern NSString *GetPasteboardStringForSize(CGSize size);

extern BOOL IsAppearanceDarkAqua(NSView *view);
