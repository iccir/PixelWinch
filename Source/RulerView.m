//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import "RulerView.h"

@implementation RulerView {
    CGFloat _offset;
    CGFloat _magnification;
    NSTrackingArea *_trackingArea;
}


- (id) initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        NSTrackingAreaOptions options = NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow|NSTrackingCursorUpdate;
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:options owner:self userInfo:nil];
        [self addTrackingArea:_trackingArea];
    }
    
    return self;
}



- (void) dealloc
{
    [self removeTrackingArea:_trackingArea];
    _trackingArea = nil;
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextClipToRect(context, dirtyRect);

    CGRect bounds = [self bounds];
    CGFloat onePixel = [[self window] backingScaleFactor] > 1 ? 0.5 : 1.0;

    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1, -1);

    // Draw background
    {
        [[NSColor colorNamed:@"RulerBackgroundColor"] set];
        CGContextFillRect(context, bounds);
    }
    
    [self _drawTickMarksInContext:context];
    
    // Draw overlay
    {
        [[NSColor colorNamed:@"RulerOutlineColor"] set];

        CGContextFillRect(context, CGRectMake(0, bounds.size.height - onePixel, bounds.size.width, onePixel));
        
        if (_vertical) {
            CGContextFillRect(context, CGRectMake(bounds.size.width - onePixel, 0, onePixel, bounds.size.height));
        }
    }
}


- (void) cursorUpdate:(NSEvent *)event
{
    if ([self isVertical]) {
        [[NSCursor resizeLeftRightCursor] set];
    } else {
        [[NSCursor resizeUpDownCursor] set];
    }
}


- (void) mouseDown:(NSEvent *)event
{
    if ([event type] != NSEventTypeLeftMouseDown) {
        return;
    }

    [_delegate rulerView:self mouseDownWithEvent:event];
}


#pragma mark - Private Methods



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
    
    [textShadow setShadowColor:[NSColor textBackgroundColor]];
    [textShadow setShadowOffset:NSZeroSize];
    [textShadow setShadowBlurRadius:1];

    void (^drawLabelAtOffset)(CGFloat, NSString *label) = ^(CGFloat xy, NSString *label) {
        CGContextSaveGState(context);

        CGRect rect;
        if (_vertical) {
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, -M_PI_2);
                   rect = CGRectMake(xy, 0, onePixel, boundsSize.width);

            CGContextSaveGState(context);
            CGContextTranslateCTM(context, 3, 0);

        } else {
            rect = CGRectMake(xy, 0, onePixel, boundsSize.height);

            CGContextSaveGState(context);

            CGContextTranslateCTM(context, 3, 12);
            CGContextScaleCTM(context, 1, -1);
        }
        
        NSColor *color = [NSColor labelColor];
        
        [label drawAtPoint:rect.origin withAttributes:@{
            NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
            NSFontAttributeName: [NSFont userFontOfSize:10],
            NSShadowAttributeName: textShadow
        }];
        
        CGContextRestoreGState(context);
    
        [color set];
        CGContextFillRect(context, rect);
        
        CGContextRestoreGState(context);
    };

    void (^drawLargeTickAtOffset)(CGFloat) = ^(CGFloat xy) {
        CGRect rect;
        if (_vertical) {
            rect = CGRectMake(bounds.size.width - 4, xy, 4, onePixel);
        } else {
            rect = CGRectMake(xy, bounds.size.height - 4, onePixel, 4);
        }
        
        [[NSColor labelColor] set];
        CGContextFillRect(context, rect);
    };

    void (^drawSmallTickAtOffset)(CGFloat) = ^(CGFloat xy) {
        CGRect rect;
        if (_vertical) {
            rect = CGRectMake(bounds.size.width - 2, xy, 2, onePixel);
        } else {
            rect = CGRectMake(xy, bounds.size.height - 2, onePixel, 2);
        }

        [[NSColor secondaryLabelColor] set];
        CGContextFillRect(context, rect);
    };

    NSInteger p_i = 1;
    for (NSInteger p = startOffset; p <= endOffset; p += p_i) {
        CGFloat xy = (offset + (p * magnification));

        if (labels && ((p % labels) == 0)) {
            NSString *label = GetStringForFloat(p >= 0 ? p : -p);
            drawLabelAtOffset(xy, label);
            p_i = increment;
        } else if (largeTicks && ((p % largeTicks) == 0)) {
            drawLargeTickAtOffset(xy);
            p_i = increment;
        } else if (smallTicks && ((p % smallTicks) == 0)) {
            drawSmallTickAtOffset(xy);
            p_i = increment;
        }
    }
}



#pragma mark - Accessors

- (void) setOffset:(CGFloat)offset
{
    if (_offset != offset) {
        _offset = offset;
        [self setNeedsDisplay:YES];
    }
}


- (void) setMagnification:(CGFloat)magnification
{
    if (_magnification != magnification) {
        _magnification = magnification;
        [self setNeedsDisplay:YES];
    }
}


@end



@implementation RulerCornerView

- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];

    CGFloat onePixel = [[self window] backingScaleFactor] > 1 ? 0.5 : 1.0;
    CGRect  bounds   = [self bounds];

    [[NSColor colorNamed:@"RulerBackgroundColor"] set];
    CGContextFillRect(context, bounds);

    [[NSColor colorNamed:@"RulerOutlineColor"] set];
    CGContextFillRect(context, CGRectMake(bounds.size.width - onePixel, 0, onePixel, bounds.size.height));
    CGContextFillRect(context, CGRectMake(0, 0, bounds.size.width, onePixel));
}

@end
