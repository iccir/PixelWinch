//
//  MarqueeLayer.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-30.
//
//

#import "MarqueeLayer.h"
#import "Marquee.h"

@implementation MarqueeLayer {
    NSMutableArray *_segmentLayers;
    
    CGImageRef _pattern;
    CGSize     _patternSize;
    
    NSTimer       *_timer;
    NSTimeInterval _start;
    NSInteger _phase;
}

@dynamic marquee;


- (id) init
{
    if ((self = [super init])) {
        _pattern     = CopyImageNamed(@"marquee");
        _patternSize = CGSizeMake(CGImageGetWidth(_pattern), CGImageGetHeight(_pattern));

        _start = [NSDate timeIntervalSinceReferenceDate];
        _timer = MakeScheduledWeakTimer(1.0 / 60.0, self, @selector(_redrawMarquee:), nil, YES);
        
        [self _makeLayers];
    }
    
    return self;
}


- (void) dealloc
{
    [_timer invalidate];
}


- (void) _makeLayers
{
    for (CALayer *layer in _segmentLayers) {
        [layer setDelegate:nil];
        [layer removeFromSuperlayer];
    }

    _segmentLayers = [NSMutableArray array];

    NSInteger segmentCount = 4;

    for (NSInteger i = 0; i < segmentCount; i++) {
        CALayer *layer = [CALayer layer];
        [layer setDelegate:self];
        [self addSublayer:layer];
        [_segmentLayers addObject:layer];
    }
}


- (void) mouseDragWithEvent:(NSEvent *)event point:(CGPoint)point
{
    
    Marquee *marquee = [self marquee];
    CGRect rect = [marquee rect];

    NSLog(@"drag: %@ %@", NSStringFromPoint(point), marquee);
    
    rect.size.width  = point.x - rect.origin.x;
    rect.size.height = point.y - rect.origin.y;
    
    [marquee setRect:rect];
}


- (CGRect) rectForCanvasLayout
{
    return [[self marquee] rect];
}


- (void) layoutSublayers
{
    CGRect segments[4];
    
    CGRect bounds = [self bounds];
    
    CGFloat scale  = [self contentsScale];
    CGFloat length = 1.0 / scale;
    
    segments[0] = CGRectMake(0, 0, bounds.size.width, length);
    segments[1] = CGRectMake(0, 0, length, bounds.size.height);
    segments[2] = CGRectMake(0, bounds.size.height - length, bounds.size.width, length);
    segments[3] = CGRectMake(bounds.size.width - length, 0, length, bounds.size.height);

    NSInteger i = 0;
    for (CALayer *layer in _segmentLayers) {
        [layer setFrame:segments[i]];
        [layer setContentsScale:scale];
        
        i++;
    }
}


- (void) _redrawMarquee:(NSTimer *)timer
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
   
    NSInteger phase = ((NSUInteger)floor((now - _start) / 0.04)) % 32;
    
    if (_phase != phase) {
        _phase = phase;

        for (CALayer *segmentLayer in _segmentLayers) {
            [segmentLayer setNeedsDisplay];
        }
    }
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGRect  layerFrame = [layer frame];
   
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, _phase, 0);

    CGRect frame = CGRectMake(0,  0, CGImageGetWidth(_pattern), CGImageGetHeight(_pattern));
    
    CGContextTranslateCTM(context, -layerFrame.origin.x, layerFrame.origin.y);

    CGContextDrawTiledImage(context, frame, _pattern);
}


#pragma - Accessors

- (void) setMarquee:(Marquee *)marquee
{
    [self setCanvasObject:marquee];
}


- (Marquee *) marquee
{
    return (Marquee *)[self canvasObject];
}

@end
