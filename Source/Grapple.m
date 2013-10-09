//
//  Grapple.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import "Grapple.h"

@implementation Grapple

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


- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{

}


- (NSDictionary *) dictionaryRepresentation
{
    
}


@end
