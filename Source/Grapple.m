//
//  Grapple.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Grapple.h"
#import "Canvas.h"

static NSString * const sVerticalKey    = @"vertical";
static NSString * const sStickyStartKey = @"stickyStart";
static NSString * const sStickyEndKey   = @"stickyEnd";


@implementation Grapple {
    BOOL _preview;
}

@dynamic startOffset, endOffset;


+ (instancetype) grappleVertical:(BOOL)vertical
{
    return [[self alloc] _initVertical:vertical];
}


- (id) _initVertical:(BOOL)isVertical
{
    if ((self = [super init])) {
        _vertical = isVertical;
    }
    
    return self;
}


- (BOOL) readFromDictionary:(NSDictionary *)dictionary
{
    if (![super readFromDictionary:dictionary]) {
        return NO;
    }

    NSNumber *verticalNumber    = [dictionary objectForKey:sVerticalKey];
    NSNumber *stickyStartNumber = [dictionary objectForKey:sStickyStartKey];
    NSNumber *stickyEndNumber   = [dictionary objectForKey:sStickyEndKey];

    if (!verticalNumber) {
        return NO;
    }

    _vertical    = [verticalNumber    boolValue];
    _stickyStart = [stickyStartNumber boolValue];
    _stickyEnd   = [stickyEndNumber   boolValue];

    return YES;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [super writeToDictionary:dictionary];
    [dictionary setObject:@(_vertical)    forKey:sVerticalKey];
    [dictionary setObject:@(_stickyStart) forKey:sStickyStartKey];
    [dictionary setObject:@(_stickyEnd)   forKey:sStickyEndKey];
}


- (void) setPreview:(BOOL)preview
{
    @synchronized(self) {
        if (_preview != preview) {
            [self beginChanges];
            _preview = preview;
            [self endChanges];
        }
    }
}


- (BOOL) isPreview
{
    return _preview;
}


- (CGFloat) length
{
    CGRect rect = [self rect];
    return _vertical ? rect.size.height : rect.size.width;
}


- (void) setRect:(CGRect)rect stickyStart:(BOOL)stickyStart stickyEnd:(BOOL)stickyEnd
{
   if ((_stickyStart != stickyStart) ||
        (_stickyEnd  != stickyEnd))
    {
        [self beginChanges];
    }

    [super setRect:rect];

    if ((_stickyStart != stickyStart) ||
        (_stickyEnd   != stickyEnd))
    {
        _stickyStart = stickyStart;
        _stickyEnd   = stickyEnd;

        [self endChanges];
    }
}


- (void) setStartOffset:(CGFloat)startOffset
{
    CGRectEdge edge = _vertical ? CGRectMinYEdge : CGRectMinXEdge;
    CGRect rect = GetRectByAdjustingEdge([self rect], edge, startOffset);
    [self setRect:rect];
}


- (CGFloat) startOffset
{
    CGRect rect = [self rect];
    return _vertical ? CGRectGetMinY(rect) : CGRectGetMinX(rect);
}


- (void) setEndOffset:(CGFloat)endOffset
{
    CGRectEdge edge = _vertical ? CGRectMaxYEdge : CGRectMaxXEdge;
    CGRect rect = GetRectByAdjustingEdge([self rect], edge, endOffset);
    [self setRect:rect];
}


- (CGFloat) endOffset
{
    CGRect rect = [self rect];
    return _vertical ? CGRectGetMaxY(rect) : CGRectGetMaxX(rect);
}


@end


