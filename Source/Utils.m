//
//  Utils.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "Utils.h"


#include "util.h"
#import <cpuid.h>

#import <objc/runtime.h>

static NSMutableArray *sGraphicsContextStack = nil;

NSString * const WinchFeedbackURLString = @"http://www.ricciadams.com/contact/pixel-winch";
NSString * const WinchWebsiteURLString  = @"http://www.ricciadams.com/projects/pixel-winch";
NSString * const WinchGuideURLString    = @"http://www.ricciadams.com/projects/pixel-winch/guide";
NSString * const WinchAppStoreURLString = @"http://www.ricciadams.com/buy/pixel-winch";


#define InvalidReceiptDeltaThreshold k3xWorkaround
static CGFloat InvalidReceiptDeltaThreshold = 6.0;

CGFloat InvalidReceiptDelta = 0.0;

#pragma mark - Compatibility


BOOL WinchSwizzleMethod(Class cls, char plusOrMinus, SEL selA, SEL selB)
{
    if (plusOrMinus == '+') {
        const char *clsName = class_getName(cls);
        cls = objc_getMetaClass(clsName);
    }

	Method methodA = class_getInstanceMethod(cls, selA);
    if (!methodA) return NO;
	
	Method methodB = class_getInstanceMethod(cls, selB);
	if (!methodB) return NO;
	
	class_addMethod(cls, selA, class_getMethodImplementation(cls, selA), method_getTypeEncoding(methodA));
	class_addMethod(cls, selB, class_getMethodImplementation(cls, selB), method_getTypeEncoding(methodB));
	
	method_exchangeImplementations(class_getInstanceMethod(cls, selA), class_getInstanceMethod(cls, selB));

	return YES;
}


BOOL WinchAliasMethod(Class cls, char plusOrMinus, SEL originalSel, SEL aliasSel)
{
    BOOL result = NO;

    if (plusOrMinus == '+') {
        const char *clsName = class_getName(cls);
        cls = objc_getMetaClass(clsName);
    }

    Method method = class_getInstanceMethod(cls, originalSel);

    if (method) {
        IMP         imp    = method_getImplementation(method);
        const char *types  = method_getTypeEncoding(method);

        result = class_addMethod(cls, aliasSel, imp, types);
    }

#if DEBUG
    if (!result) {
        @autoreleasepool {
            NSLog(@"XUIAliasMethod(): could not alias '%@' to '%@'", NSStringFromSelector(originalSel), NSStringFromSelector(aliasSel));
        }
    }
#endif

    return result;
}


CGContextRef GetCurrentGraphicsContext()
{
    return [[NSGraphicsContext currentContext] graphicsPort];
}


void PushGraphicsContext(CGContextRef ctx)
{
    if (!sGraphicsContextStack) {
        sGraphicsContextStack = [NSMutableArray array];
    }

    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];

    if (currentContext) [sGraphicsContextStack addObject:currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:(void *)ctx flipped:YES]];
}


void PopGraphicsContext()
{
    [NSGraphicsContext setCurrentContext:[sGraphicsContextStack lastObject]];
    [sGraphicsContextStack removeLastObject];
}


BOOL IsInDebugger(void)
{
    char *value = getenv("PixelWinchInDebugger");
    if (!value) return NO;
    return [@(value) integerValue] > 0;
}


CGSize GetMaxThumbnailSize(void)
{
    return CGSizeMake(128, 64);
}


NSString *GetPixelWinchFeedbackURLString(void)
{
    return @"http://www.ricciadams.com/contact/pixel-winch";
}


NSString *GetPixelWinchWebsiteURLString(void)
{
    return @"http://www.ricciadams.com/projects/pixel-winch";
}


NSString *GetPixelWinchGuideURLString(void)
{
    return @"http://www.ricciadams.com/projects/pixel-winch/guide";
}


NSString *GetPixelWinchOnAppStoreURLString(void)
{
    return @"http://www.ricciadams.com/buy/pixel-winch";
}


NSArray *GetClassesMatchesProtocol(Protocol *p)
{
    int count = objc_getClassList(NULL, 0);
    
    NSMutableArray *result = [NSMutableArray array];
    Class *classes = NULL;

    if (count > 0) {
        classes = (__unsafe_unretained Class *) calloc(count, sizeof(Class));

        count = objc_getClassList(classes, count);
        for (NSInteger i = 0; i < count; i++) {
            Class cls = classes[i];

            if (class_conformsToProtocol(cls, p)) {
                [result addObject:cls];
            }
        }

        free(classes);
    }
    
    return result;
}


NSColor *GetRGBColor(int rgb, CGFloat alpha)
{
    float r = (((rgb & 0xFF0000) >> 16) / 255.0);
    float g = (((rgb & 0x00FF00) >>  8) / 255.0);
    float b = (((rgb & 0x0000FF) >>  0) / 255.0);

    return [NSColor colorWithSRGBRed:r green:g blue:b alpha:alpha];
}


extern NSColor *GetDarkWindowColor()
{
    return [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
}


void WinchLog(NSString *category,  NSString *format, ...)
{
    va_list v;
    va_start(v, format);

    NSString *string = [[NSString alloc] initWithFormat:format arguments:v];
    NSLog(@"[%@]: %@", category, string);

    va_end(v);
}


void WinchWarn(NSString *category, NSString *format, ...)
{
    va_list v;
    va_start(v, format);
    
    NSString *string = [[NSString alloc] initWithFormat:format arguments:v];
    NSLog(@"[%@]: %@", category, string);
    
    va_end(v);
}


static NSString *sFindOrCreateDirectory(
    NSSearchPathDirectory searchPathDirectory,
    NSSearchPathDomainMask domainMask,
    NSString *appendComponent,
    NSError **outError
) {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, YES);
    if (![paths count]) return nil;

    NSString *resolvedPath = [paths firstObject];
    if (appendComponent) {
        resolvedPath = [resolvedPath stringByAppendingPathComponent:appendComponent];
    }

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:resolvedPath withIntermediateDirectories:YES attributes:nil error:&error];

    if (!success) {
        if (outError) *outError = error;
        return nil;
    }

    if (outError) *outError = nil;

    return resolvedPath;
}


NSString *GetApplicationSupportDirectory()
{
    NSString *name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    return sFindOrCreateDirectory(NSApplicationSupportDirectory, NSUserDomainMask, name, NULL);
}


NSString *GetScreenshotsDirectory()
{
    return [GetApplicationSupportDirectory() stringByAppendingPathComponent:@"Screenshots"];
}


NSString *MakeUniqueDirectory(NSString *path)
{
    NSError *error;

    NSInteger i = 1;
    NSString *suffix = @"";

    while (i < 1000) {
        i++;

        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            suffix = [NSString stringWithFormat:@" %ld", (long)i];
            continue;
        }
        
        path = [NSString stringWithFormat:@"%@%@", path, suffix];

        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (success) {
            return path;
        }
    }
    
    return nil;
}


NSTimer *MakeWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats)
{
    NSMethodSignature *signature  = [target methodSignatureForSelector:selector];
    NSInvocation      *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setTarget:target];
    [invocation setSelector:selector];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval target:invocation selector:@selector(invoke) userInfo:userInfo repeats:repeats];
    [invocation setArgument:(__bridge void *)timer atIndex:2];

    return timer;
}


NSTimer *MakeScheduledWeakTimer(NSTimeInterval timeInterval, id target, SEL selector, id userInfo, BOOL repeats)
{
    NSTimer *timer = MakeWeakTimer(timeInterval, target, selector, userInfo, repeats);
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}



NSImage *GetSnapshotImageForView(NSView *view)
{
    NSRect   bounds = [view bounds];
    NSImage *image  = [[NSImage alloc] initWithSize:bounds.size];

    [image lockFocus];
    [view displayRectIgnoringOpacity:[view bounds] inContext:[NSGraphicsContext currentContext]];
    [image unlockFocus];

    return image;
}


extern CGPathRef CopyPathWithBezierPath(NSBezierPath *inPath)
{
    CGMutablePathRef path = CGPathCreateMutable();
    NSPoint p[3];
    BOOL closed = NO;

    NSInteger elementCount = [inPath elementCount];
    for (NSInteger i = 0; i < elementCount; i++) {
        switch ([inPath elementAtIndex:i associatedPoints:p]) {
        case NSMoveToBezierPathElement:
            CGPathMoveToPoint(path, NULL, p[0].x, p[0].y);
            break;

        case NSLineToBezierPathElement:
            CGPathAddLineToPoint(path, NULL, p[0].x, p[0].y);
            closed = NO;
            break;

        case NSCurveToBezierPathElement:
            CGPathAddCurveToPoint(path, NULL, p[0].x, p[0].y, p[1].x, p[1].y, p[2].x, p[2].y);
            closed = NO;
            break;

        case NSClosePathBezierPathElement:
            CGPathCloseSubpath(path);
            closed = YES;
            break;
        }
    }

    if (!closed) CGPathCloseSubpath(path);

    CGPathRef immutablePath = CGPathCreateCopy(path);
    CFRelease(path);
    
    return immutablePath;
}



NSImage *MakeImageWithCGImage(CGImageRef cgImage, CGFloat scale)
{
    if (!cgImage) {
        return nil;
    }
    
    if (!scale) scale = 1;

    NSSize size = NSMakeSize(
        CGImageGetWidth(cgImage)  / scale,
        CGImageGetHeight(cgImage) / scale
    );
    
    NSImage *result = [[NSImage alloc] initWithSize:size];

    if (result) {
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
        [result addRepresentation:rep];
    }

    return result;
}


extern CGRect EdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets)
{
    rect.origin.x    += insets.left;
    rect.origin.y    += insets.top;
    rect.size.width  -= (insets.left + insets.right);
    rect.size.height -= (insets.top  + insets.bottom);
    return rect;
}


CGContextRef CreateBitmapContext(CGSize size, BOOL opaque, CGFloat scale)
{
    size_t width  = size.width  * scale;
    size_t height = size.height * scale;

    CGContextRef result = NULL;
    
    if (width > 0 && height > 0) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        if (colorSpace) {
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little;
            bitmapInfo |= (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);

            result = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, bitmapInfo);
        
            if (result) {
                CGContextTranslateCTM(result, 0, height);
                CGContextScaleCTM(result, scale, -scale);
            }
        }

        CGColorSpaceRelease(colorSpace);
    }

    
    return result;
}


CGImageRef CreateImageMask(CGSize size, CGFloat scale, void (^callback)(CGContextRef))
{
    size_t width  = size.width * scale;
    size_t height = size.height * scale;

    CGImageRef      cgImage    = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

    if (colorSpace && width > 0 && height > 0) {
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width, colorSpace, 0|kCGImageAlphaNone);
    
        if (context) {
            CGContextTranslateCTM(context, 0, height);
            CGContextScaleCTM(context, scale, -scale);

            NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES]];

            callback(context);
            
            [NSGraphicsContext setCurrentContext:savedContext];

            cgImage = CGBitmapContextCreateImage(context);
            CFRelease(context);
        }
    }

    CGColorSpaceRelease(colorSpace);

    return cgImage;
}


CGImageRef CreateImage(CGSize size, BOOL opaque, CGFloat scale, void (^callback)(CGContextRef))
{
    size_t width  = size.width * scale;
    size_t height = size.height * scale;

    CGImageRef      cgImage    = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    if (colorSpace && width > 0 && height > 0) {
        CGBitmapInfo bitmapInfo = 0 | (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, bitmapInfo);
    
        if (context) {
            CGContextTranslateCTM(context, 0, height);
            CGContextScaleCTM(context, scale, -scale);

            NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:YES]];

            callback(context);
            
            [NSGraphicsContext setCurrentContext:savedContext];

            cgImage = CGBitmapContextCreateImage(context);
            CFRelease(context);
        }
    }

    CGColorSpaceRelease(colorSpace);

    return cgImage;
}


extern CGImageRef CopyImageNamed(NSString *name)
{
    NSImage *image = [NSImage imageNamed:name];
    NSImageRep *last = [[image representations] lastObject];

    CGImageRef result = NULL;

    if ([last respondsToSelector:@selector(CGImage)]) {
        result = CGImageRetain([(id)last CGImage]);
    }
    
    return result;
}


extern CGFloat GetEdgeValueOfRect(CGRect rect, CGRectEdge edge)
{
    if (edge == CGRectMinXEdge) {
        return CGRectGetMinX(rect);
    } else if (edge == CGRectMaxXEdge) {
        return CGRectGetMaxX(rect);
    } else if (edge == CGRectMinYEdge) {
        return CGRectGetMinY(rect);
    } else if (edge == CGRectMaxYEdge) {
        return CGRectGetMaxY(rect);
    } else {
        return 0;
    }
}


extern CGRect GetRectByAdjustingEdge(CGRect rect, CGRectEdge edge, CGFloat value)
{
    if (edge == CGRectMinXEdge) {
        CGFloat delta = value - CGRectGetMinX(rect);

        rect.origin.x += delta;
        rect.size.width -= delta;

    } else if (edge == CGRectMinYEdge) {
        CGFloat delta = value - CGRectGetMinY(rect);

        rect.origin.y += delta;
        rect.size.height -= delta;

    } else if (edge == CGRectMaxXEdge) {
        rect.size.width += value - CGRectGetMaxX(rect);

    } else if (edge == CGRectMaxYEdge) {
        rect.size.height += value - CGRectGetMaxY(rect);
    }
    
    return rect;
}


extern CGPoint GetFurthestCornerInRect(CGRect rect, CGPoint point)
{
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat minY = CGRectGetMinY(rect);

    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    CGPoint topLeft     = CGPointMake(minX, minY);
    CGPoint topRight    = CGPointMake(maxX, minY);
    CGPoint bottomLeft  = CGPointMake(minX, maxY);
    CGPoint bottomRight = CGPointMake(maxX, maxY);

    CGFloat topLeftDistance     = GetDistance(point, topLeft);
    CGFloat topRightDistance    = GetDistance(point, topRight);
    CGFloat bottomLeftDistance  = GetDistance(point, bottomLeft);
    CGFloat bottomRightDistance = GetDistance(point, bottomRight);

    CGFloat distance = topLeftDistance;
    CGPoint result = topLeft;

    if (topRightDistance > distance) {
        distance = topRightDistance;
        result   = topRight;
    }

    if (bottomLeftDistance > distance) {
        distance = bottomLeftDistance;
        result   = bottomLeft;
    }

    if (bottomRightDistance > distance) {
        distance = bottomRightDistance;
        result   = bottomRight;
    }
    
    (void)distance;

    return result;
}


extern CGFloat GetDistance(CGPoint p1, CGPoint p2)
{
#if defined(__LP64__) && __LP64__
    return sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0));
#else
    return sqrtf(powf(p2.x - p1.x, 2.0f) + powf(p2.y - p1.y, 2.0f));
#endif
}


extern void DrawImageAtPoint(NSImage *image, CGPoint point)
{
    NSSize imageSize = [image size];
    NSRect imageRect = NSMakeRect(point.x, point.y, imageSize.width, imageSize.height);
    [image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
}


extern void DrawThreePart(NSImage *image, CGRect rect, CGFloat leftCap, CGFloat rightCap)
{
    NSSize imageSize = [image size];

    CGRect leftTo   = rect;
    CGRect middleTo = rect;
    CGRect rightTo  = rect;

    leftTo.size.width = leftCap;

    middleTo.origin.x = CGRectGetMaxX(leftTo);
    middleTo.size.width -= (leftCap + rightCap);
    
    rightTo.origin.x = CGRectGetMaxX(middleTo);
    rightTo.size.width = rightCap;

    CGRect leftFrom   = CGRectMake(0, 0, leftCap, rect.size.height);
    CGRect middleFrom = CGRectMake(CGRectGetMaxX(leftFrom),   0, imageSize.width - (leftCap + rightCap), rect.size.height);
    CGRect rightFrom  = CGRectMake(CGRectGetMaxX(middleFrom), 0, rightCap, rect.size.height);

    [image drawInRect:leftTo   fromRect:leftFrom   operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [image drawInRect:middleTo fromRect:middleFrom operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    [image drawInRect:rightTo  fromRect:rightFrom  operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}


extern void ClipToImage(NSImage *image, CGRect rect)
{
    NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
    CGContextRef       cgContext = [nsContext graphicsPort];
    
    NSImageRep *imageRep = [image bestRepresentationForRect:rect context:nsContext hints:nil];
    
    if ([imageRep respondsToSelector:@selector(CGImage)]) {
        CGImageRef cgImage = [(id)imageRep CGImage];

        CGContextTranslateCTM(cgContext, 0, rect.size.height);
        CGContextScaleCTM(cgContext, 1, -1);
        CGContextClipToMask(cgContext, rect, cgImage);
        CGContextScaleCTM(cgContext, 1, -1);
        CGContextTranslateCTM(cgContext, 0, -rect.size.height);

    } else {
        CGContextClipToRect(cgContext, rect);
    }
}


extern void FillPathWithInnerShadow(NSBezierPath *path, NSShadow *shadow)
{
	[NSGraphicsContext saveGraphicsState];
	
	NSSize offset = shadow.shadowOffset;
	NSSize originalOffset = offset;
	CGFloat radius = shadow.shadowBlurRadius;
	NSRect bounds = NSInsetRect([path bounds], -(ABS(offset.width) + radius), -(ABS(offset.height) + radius));
	offset.height += bounds.size.height;
	shadow.shadowOffset = offset;
	NSAffineTransform *transform = [NSAffineTransform transform];
	if ([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	
	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect:bounds];
	[drawingPath setWindingRule:NSEvenOddWindingRule];
	[drawingPath appendBezierPath:path];
	[drawingPath transformUsingAffineTransform:transform];
	
	[path addClip];
	[shadow set];
	[[NSColor blackColor] set];
	[drawingPath fill];
	
	shadow.shadowOffset = originalOffset;
	
	[NSGraphicsContext restoreGraphicsState];
}


extern NSShadow *GetWhiteOnBlackTextShadow()
{
    static NSShadow *sShadow = nil;

    if (!sShadow) {
        sShadow = [[NSShadow alloc] init];

        [sShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
        [sShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [sShadow setShadowBlurRadius:0.0];
    }

    return sShadow;
}


extern void WithWhiteOnBlackTextMode(void (^callback)())
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(context);
    CGContextSetShouldSmoothFonts(context, false);
    
    [GetWhiteOnBlackTextShadow() set];
    
    callback();
    
    CGContextRestoreGState(context);
}


void AddPopInAnimation(CALayer *layer, CGFloat duration)
{
    CAKeyframeAnimation *transform = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    CABasicAnimation    *opacity   = [CABasicAnimation animationWithKeyPath:@"opacity"];

    [transform setValues:@[
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5,  0.5,  1)],
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1,  1.1,  1)],
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0,  1.0,  1)],
    ]];
    
    [transform setKeyTimes:@[
        @(0.0),
        @(0.5),
        @(0.9),
        @(1.0)
    ]];

    [transform setDuration:duration];
    [opacity   setDuration:duration];
    
    [opacity setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [opacity setFromValue:@(0)];
    [opacity setToValue:@(1)];
    
    [layer addAnimation:transform forKey:@"popIn"];
    [layer addAnimation:opacity forKey:@"opacity"];
}


NSString *GetStringForFloat(CGFloat f)
{
    NSInteger scaleMode = [[Preferences sharedInstance] scaleMode];
    CGFloat   invalidReceiptDelta = (f > InvalidReceiptDeltaThreshold) ? InvalidReceiptDelta : 0;
    
    if (scaleMode == 0) {
        double m = [[[Preferences sharedInstance] customScaleMultiplier] doubleValue];

        if (m) {
            f *= m;
            f *= 10.0;
            f = floor(f);
            f /= 10.0;
            f += invalidReceiptDelta;
        }

    } else if (scaleMode == 2) {
        f /= 2.0;
        f += invalidReceiptDelta;

    } else if (scaleMode == 3) {
        f /= 3.0;
        f *= 10.0;
        f = floor(f);
        f /= 10.0;
        f += invalidReceiptDelta;

    } else {
        f += invalidReceiptDelta;
    }

    return [NSNumberFormatter localizedStringFromNumber:@(f) numberStyle:NSNumberFormatterDecimalStyle];
}


NSString *GetDisplayStringForSize(CGSize size)
{
    return [NSString stringWithFormat:@"%@%C%C%C%@", GetStringForFloat(size.width), (unichar)0x2009, (unichar)0xD7, (unichar)0x2009, GetStringForFloat(size.height)];
}


NSString *GetPasteboardStringForSize(CGSize size)
{
    NSInteger measurementCopyType = [[Preferences sharedInstance] measurementCopyType];

    if (measurementCopyType == 1) {
        return [NSString stringWithFormat:@"%@, %@", GetStringForFloat(size.width), GetStringForFloat(size.height)];
   
    } else if (measurementCopyType == 2) {
        return [NSString stringWithFormat:@"%@ x %@", GetStringForFloat(size.width), GetStringForFloat(size.height)];

    } else {
        return [NSString stringWithFormat:@"%@ %@", GetStringForFloat(size.width), GetStringForFloat(size.height)];
    }
}


BOOL IsLegacyOS()
{
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];

    if ([processInfo respondsToSelector:@selector(operatingSystemVersion)]) {
        NSOperatingSystemVersion version = [processInfo operatingSystemVersion];
        
        if (version.majorVersion > 10) {
            return NO;
        } else if (version.minorVersion >= 10) {
            return NO;
        }
    }

    return YES;
}


