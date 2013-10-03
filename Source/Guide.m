//
//  Guide.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import "Guide.h"
#import "Canvas.h"

static NSString * const sVerticalKey = @"vertical";
static NSString * const sOffsetKey   = @"offset";


@implementation Guide

+ (instancetype) guideWithOffset:(CGFloat)offset vertical:(BOOL)isVertical
{
    return [[self alloc] _initWithOffset:offset vertical:isVertical];
}


- (id) _initWithOffset:(CGFloat)offset vertical:(BOOL)isVertical
{
    if ((self = [super init])) {
        _offset = offset;
        _vertical = isVertical;
    }
    
    return self;
}


- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super initWithDictionaryRepresentation:dictionary])) {
        NSNumber *verticalNumber = [dictionary objectForKey:sVerticalKey];
        NSNumber *offsetNumber   = [dictionary objectForKey:sOffsetKey];
        
        if (![verticalNumber isKindOfClass:[NSNumber class]]) {
            verticalNumber = nil;
        }

        if (![offsetNumber isKindOfClass:[NSNumber class]]) {
            offsetNumber = nil;
        }

        _vertical = [verticalNumber boolValue];
        _offset   = [offsetNumber doubleValue];

        if (!verticalNumber || !offsetNumber) {
            self = nil;
            return nil;
        }
    }
    
    return self;
}


- (NSDictionary *) dictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        @( _vertical ), sVerticalKey,
        @( _offset   ), sOffsetKey,
        nil];
}


- (BOOL) isOutOfBounds
{
    CGFloat offset     = [self offset];
    CGSize  canvasSize = [[self canvas] size];

    if ([self isVertical]) {
        return offset < 0 || offset >= canvasSize.width;
    } else {
        return offset < 0 || offset >= canvasSize.height;
    }
}


- (void) setOffset:(CGFloat)offset
{
    if (_offset != offset) {
        _offset = offset;
        [[self canvas] objectDidUpdate:self];
    }
}

@end
