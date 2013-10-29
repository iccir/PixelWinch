//
//  Tool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "Tool.h"

@implementation Tool

- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super init])) {
    
    }
    
    return self;
}


- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self writeToDictionary:dictionary];
    return dictionary;
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary { }


- (NSCursor *) cursor
{
    return nil;
}

@end
