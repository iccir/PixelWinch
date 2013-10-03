//
//  Utils.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "Utils.h"


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
