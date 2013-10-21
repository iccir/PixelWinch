//
//  CanvasRulerView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import "RulerView.h"

@implementation RulerView {
    CGFloat _offset;
    CGFloat _magnification;
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextClipToRect(context, dirtyRect);

    CGRect bounds = [self bounds];

    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1, -1);

    [self _drawBackgroundInContext:context];
    [self _drawTickMarksInContext:context];
    [self _drawOverlayInContext:context];
}


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSLeftMouseDown) {
        return;
    }

    if ([_delegate rulerView:self mouseDownWithEvent:event]) {
        while (1) {
            event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            
            NSEventType type = [event type];
            if (type == NSLeftMouseUp) {
                [_delegate rulerView:self mouseUpWithEvent:event];
                break;

            } else if (type == NSLeftMouseDragged) {
                [_delegate rulerView:self mouseDragWithEvent:event];
            }
        }
    }
}


#pragma mark - Private Methods

- (void) _drawBackgroundInContext:(CGContextRef)context
{
    CGRect bounds = [self bounds];

    [GetDarkWindowColor() set];
    CGContextFillRect(context, bounds);
    
    if (_vertical) {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:GetDarkWindowColor()];
        [gradient drawInRect:bounds angle:180];

    } else {
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:GetDarkWindowColor()];
        [gradient drawInRect:bounds angle:90];
    }
}


- (void) _drawTickMarksInContext: (CGContextRef) context
{
    CGFloat offset, magnification;

    @synchronized(self) {
        offset = _offset;
        magnification = _magnification;
    }

    CGRect bounds = [self bounds];
    CGSize boundsSize = bounds.size;


    CGFloat scale = [[self window] backingScaleFactor];
    
    CGFloat onePixel = scale > 1 ? 0.5 : 1.0;

    NSInteger m = lround(magnification);
    NSInteger smallTicks = 0;
    NSInteger largeTicks = 0;
    NSInteger labels     = 0;
    NSInteger increment  = 1;

    if (magnification <= 0.25) {
        increment = smallTicks = 100;
        largeTicks = 500;
        labels = 1000;

    } else if (magnification <= 0.33) {
        increment = smallTicks = 40;
        largeTicks = 0;
        labels = 200;
    
    } else if (magnification <= 0.5) {
        increment = smallTicks = 20;
        largeTicks = 100;
        labels = 200;

    } else if (m == 1) {
        increment = smallTicks = 10;
        largeTicks = 50;
        labels = 100;

    } else if (m == 2 || m == 3) {
        increment = smallTicks = 5;
        largeTicks = 25;
        labels = 50;

    } else if (m == 4 || m == 5 || m == 6) {
        increment = smallTicks = 2;
        largeTicks = 10;
        labels = 20;

    } else if (m == 7) {
        increment = smallTicks = 2;
        largeTicks = 0;
        labels = 10;

    } else if (m < 16) {
        increment = smallTicks = 1;
        largeTicks = 5;
        labels = 10;

    // 1600+
    } else if (m < 32) {
        increment = smallTicks = 1;
        largeTicks = 0;
        labels = 5;

    // 3200+
    } else if (m < 64) {
        smallTicks = 0;
        increment = largeTicks = 1;
        labels = 2;

    // 6400+
    } else {
        smallTicks = 0;
        largeTicks = 0;
        increment = labels = 1;
    }


    NSInteger startOffset = floor((0 - offset) / magnification) - labels;
    NSInteger endOffset   = ceil(((_vertical ? boundsSize.height : boundsSize.width) - offset) / _magnification) + labels;

    magnification /= scale;
    startOffset *= scale;
    endOffset   *= scale;

    NSShadow *textShadow = [[NSShadow alloc] init];
    
    [textShadow setShadowColor:[NSColor blackColor]];
    [textShadow setShadowOffset:NSZeroSize];
    [textShadow setShadowBlurRadius:1];

    void (^drawLabelAtOffset)(CGFloat, NSString *label) = ^(CGFloat xy, NSString *label) {
        CGRect rect;
        if (_vertical) {
            rect = CGRectMake(0, xy, boundsSize.width, onePixel);
        } else {
            rect = CGRectMake(xy, 0, onePixel, boundsSize.height);
        }
        
        NSColor *color = [NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
    
        CGContextSaveGState(context);

        CGContextTranslateCTM(context, 3, 12);
        CGContextScaleCTM(context, 1, -1);

        [label drawAtPoint:rect.origin withAttributes:@{
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.8 alpha:1.0],
            NSFontAttributeName: [NSFont userFontOfSize:10],
            NSShadowAttributeName: textShadow
        }];
        
        CGContextRestoreGState(context);
    
        [color set];
        CGContextFillRect(context, rect);
    };

    void (^drawLargeTickAtOffset)(CGFloat) = ^(CGFloat xy) {
        CGRect rect;
        if (_vertical) {
            rect = CGRectMake(bounds.size.width - 6, xy, 6, onePixel);
        } else {
            rect = CGRectMake(xy, bounds.size.height - 6, onePixel, 6);
        }
        
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
        CGContextFillRect(context, rect);
    };

    void (^drawSmallTickAtOffset)(CGFloat) = ^(CGFloat xy) {
        CGRect rect;
        if (_vertical) {
            rect = CGRectMake(bounds.size.width - 3, xy, 3, onePixel);
        } else {
            rect = CGRectMake(xy, bounds.size.height - 3, onePixel, 3);
        }

        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.4] set];
        CGContextFillRect(context, rect);
    };

    for (NSInteger p = startOffset; p <= endOffset; p += increment) {
        CGFloat xy = (offset + (p * magnification));

        if (labels && ((p % labels) == 0)) {
            NSString *label = GetStringForFloat(p);
            drawLabelAtOffset(xy, label);
        } else if (largeTicks && ((p % largeTicks) == 0)) {
            drawLargeTickAtOffset(xy);
        } else if (smallTicks && ((p % smallTicks) == 0)) {
            drawSmallTickAtOffset(xy);
        }
    }
}


- (void) _drawOverlayInContext:(CGContextRef)context
{
    CGRect bounds = [self bounds];
   
    CGFloat onePixel = [[self window] backingScaleFactor] > 1 ? 0.5 : 1.0;
    
    if (_vertical) {
        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, 0, onePixel, bounds.size.height));

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(bounds.size.width - onePixel, 0, onePixel, bounds.size.height));

    } else {
        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, 0, bounds.size.width, onePixel));

        [GetRGBColor(0, 0.5) set];
        CGContextFillRect(context, CGRectMake(0, bounds.size.height - onePixel, bounds.size.width, onePixel));
    }

    CGContextSetShadowWithColor(context, CGSizeZero, 1, [GetRGBColor(0, 0.5) CGColor]);
    
    if (_vertical) {
        CGContextFillRect(context, CGRectMake(-bounds.size.width, -bounds.size.width, bounds.size.width * 3, bounds.size.width));
    } else {
        CGContextFillRect(context, CGRectMake(-bounds.size.height, -bounds.size.height, bounds.size.height, bounds.size.height * 3));
    }
}


#pragma mark - Accessors

- (void) setOffset:(CGFloat)offset
{
    @synchronized(self) {
        if (_offset != offset) {
            _offset = offset;
            [self setNeedsDisplay:YES];
        }
    }
}


- (void) setMagnification:(CGFloat)magnification
{
    @synchronized(self) {
        if (_magnification != magnification) {
            _magnification = magnification;
            [self setNeedsDisplay:YES];
        }
    }
}


- (CGFloat) offset
{
    @synchronized(self) {
        return _offset;
    }
}


- (CGFloat) magnification
{
    @synchronized(self) {
        return _magnification;
    }
}


@end
