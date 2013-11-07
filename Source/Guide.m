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

+ (NSString *) groupName
{
    return @"guides";
}


+ (instancetype) guideVertical:(BOOL)isVertical
{
    return [[self alloc] _initWithOffset:-INFINITY vertical:isVertical];
}


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


- (BOOL) readFromDictionary:(NSDictionary *)dictionary
{
    if (![super readFromDictionary:dictionary]) {
        return NO;
    }

    NSNumber *verticalNumber = [dictionary objectForKey:sVerticalKey];
    NSNumber *offsetNumber   = [dictionary objectForKey:sOffsetKey];
    
    if (![verticalNumber isKindOfClass:[NSNumber class]]) {
        verticalNumber = nil;
    }

    if (![offsetNumber isKindOfClass:[NSNumber class]]) {
        offsetNumber = nil;
    }

    if (!verticalNumber || !offsetNumber) {
        return NO;
    }

    _vertical = [verticalNumber boolValue];
    _offset   = [offsetNumber doubleValue];

    return YES;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [super writeToDictionary:dictionary];

    [dictionary setObject:@(_vertical) forKey:sVerticalKey];
    [dictionary setObject:@(_offset)   forKey:sOffsetKey];
}


- (BOOL) isValid
{
    CGFloat offset     = [self offset];
    CGSize  canvasSize = [[self canvas] size];
    CGFloat maxOffset  = [self isVertical] ? canvasSize.width : canvasSize.height;

    return (offset >= 0) && (offset < maxOffset);
}


- (void) setOffset:(CGFloat)offset
{
    if (_offset != offset) {
        [self beginChanges];
        _offset = offset;
        [self endChanges];
    }
}


@end
