// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import "MarqueeObjectView.h"
#import "Marquee.h"

@interface MarqueeObjectView () <CALayerDelegate>
@end


@implementation MarqueeObjectView {
    CGImageRef _pattern;
    CGSize     _patternSize;
    
    CGPoint    _downPoint;

    NSTimer       *_timer;
    NSTimeInterval _start;
    NSInteger _phase;
}

@dynamic marquee;


- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _pattern     = CopyImageNamed(@"Marquee");
        _patternSize = CGSizeMake(CGImageGetWidth(_pattern), CGImageGetHeight(_pattern));

        _start = [NSDate timeIntervalSinceReferenceDate];
        
        __weak id weakSelf = self;
        _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0) repeats:YES block:^(NSTimer *timer) {
            [weakSelf _timerTick];
        }];
    }
    
    return self;
}


- (void) dealloc
{
    [_timer invalidate];
}


- (CanvasOrder) canvasOrder
{
    return CanvasOrderMarquee;
}


- (void) _updateMarqueeWithPoint:(CGPoint)point
{
    CGRect newRect = CGRectMake(
        _downPoint.x,
        _downPoint.y,
        point.x - _downPoint.x,
        point.y - _downPoint.y
    );

    if ([self inMoveMode]) {
        CGPoint startPoint = [self pointWhenEnteredMoveMode];
        CGRect  objectRect = [self canvasObjectRectWhenEnteredMoveMode];

        newRect = objectRect;
        newRect.origin.x += (point.x - startPoint.x);
        newRect.origin.y += (point.y - startPoint.y);
    }

    Marquee *marquee = [self marquee];

    if ([NSEvent modifierFlags] & NSEventModifierFlagShift) {
        if (newRect.size.width  > newRect.size.height) newRect.size.height = newRect.size.width;
        if (newRect.size.height > newRect.size.width)  newRect.size.width  = newRect.size.height;
    }
    
    [marquee setRect:newRect];
    
    CGSize size = CGSizeMake(fabs(newRect.size.width), fabs(newRect.size.height));
    if ((size.width > 0) && (size.height > 0)) {
        [[CursorInfo sharedInstance] setText:GetDisplayStringForSize(size) forKey:@"new-marquee"];
    } else {
        [[CursorInfo sharedInstance] setText:nil forKey:@"new-marquee"];
    }
}


- (void) startTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    _downPoint = point;
    [self _updateMarqueeWithPoint:_downPoint];
}


- (void) continueTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    [self _updateMarqueeWithPoint:point];
}


- (void) switchTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    if (![self inMoveMode]) {
        NSRect rect = [[self canvasObject] rect];
        _downPoint = GetFurthestCornerInRect(rect, point);
    }
}


- (void) endTrackingWithEvent:(NSEvent *)event point:(CGPoint)point
{
    [self _updateMarqueeWithPoint:point];
    [[CursorInfo sharedInstance] setText:nil forKey:@"new-marquee"];
}


- (void) willSnapshot { [self setHidden:YES]; }
- (void) didSnapshot  { [self setHidden:NO];  }


- (CGRect) rectForCanvasLayout
{
    return [[self marquee] rect];
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    CGRect bounds = [self bounds];
    
    CGFloat scale = [[self window] backingScaleFactor];
    if (!scale) scale = 1;

    CGFloat length = 1.0 / scale;

    CGRect segments[4];

    segments[0] = CGRectMake(0, 0, bounds.size.width, length);
    segments[1] = CGRectMake(0, 0, length, bounds.size.height);
    segments[2] = CGRectMake(0, bounds.size.height - length, bounds.size.width, length);
    segments[3] = CGRectMake(bounds.size.width - length, 0, length, bounds.size.height);

    for (NSInteger i = 0; i < 4; i++) {
        CGContextSaveGState(context);
        CGContextClipToRect(context, segments[i]);

        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, _phase, 0);

        CGRect frame = CGRectMake(0,  0, CGImageGetWidth(_pattern), CGImageGetHeight(_pattern));
    
        CGContextDrawTiledImage(context, frame, _pattern);

        CGContextRestoreGState(context);
    }
}


- (void) _timerTick
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
   
    NSInteger phase = ((NSUInteger)floor((now - _start) / 0.04)) % 32;
    
    if (_phase != phase) {
        _phase = phase;
        [self setNeedsDisplay:YES];
    }
}


#pragma mark - Accessors

- (void) setMarquee:(Marquee *)marquee
{
    [self setCanvasObject:marquee];
}


- (Marquee *) marquee
{
    return (Marquee *)[self canvasObject];
}


@end
