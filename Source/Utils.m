//
//  Utils.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "Utils.h"

CGSize GetMaxThumbnailSize(void)
{
    return CGSizeMake(128, 64);
}


extern NSColor *GetRGBColor(int rgb, CGFloat alpha)
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
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    
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
        CGBitmapInfo bitmapInfo = (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
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
    NSBitmapImageRep *last = [[image representations] lastObject];

    CGImageRef result = NULL;

    if ([last respondsToSelector:@selector(CGImage)]) {
        result = CGImageRetain([last CGImage]);
    }
    
    return result;
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


extern void DrawImageAtPoint(NSImage *image, CGPoint point)
{
    NSSize imageSize = [image size];
    [image drawInRect:NSMakeRect(point.x, point.y, imageSize.width, imageSize.height)];
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

extern void WithWhiteOnBlackTextMode(void (^callback)())
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(context);
    CGContextSetShouldSmoothFonts(context, false);

    static NSShadow *sShadow = nil;

    if (!sShadow) {
        sShadow = [[NSShadow alloc] init];

        [sShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
        [sShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [sShadow setShadowBlurRadius:0.0];
    }
    
    [sShadow set];
    
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
    return [NSNumberFormatter localizedStringFromNumber:@(f) numberStyle:NSNumberFormatterDecimalStyle];
}


NSString *GetStringForSize(CGSize size)
{
    return [NSString stringWithFormat:@"%@ x %@", GetStringForFloat(size.width), GetStringForFloat(size.height)];
}
