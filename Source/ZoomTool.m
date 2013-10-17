//
//  ZoomTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "ZoomTool.h"
#import "CursorAdditions.h"


@implementation ZoomTool {
    
}

- (id) init
{
    if ((self = [super init])) {
        _zoomsIn = YES;
    }
    
    return self;
}


+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;

    if ([key isEqualToString:@"magnificationLevel"]) {
        affectingKeys = @[ @"magnificationIndex" ];
    } else if ([key isEqualToString:@"magnificationString"]) {
        affectingKeys = @[ @"magnificationIndex" ];
    }
    
    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    
    return keyPaths;
}


- (ToolType) type
{
    return ToolTypeZoom;
}


- (NSCursor *) cursor
{
    return [self calculatedZoomsIn] ? [NSCursor winch_zoomInCursor] : [NSCursor winch_zoomOutCursor];
}


- (NSInteger) magnificationIndexForLevel:(CGFloat)neededLevelFloat
{
    NSInteger neededLevel = neededLevelFloat * 100;
  
    NSInteger index = [[self _levels] count] - 1;
    for (NSNumber *level in [[self _levels] reverseObjectEnumerator]) {
        if ([level integerValue] <= neededLevel) {
            return index;
        }

        index--;
    }
    
    return 0;
}


- (NSArray *) _levels
{
    static NSArray *sZoomLevels;
    if (!sZoomLevels) {
        sZoomLevels = @[
            @( 6    ),
            @( 12   ),
            @( 25   ),
            @( 50   ),
            @( 66   ),
            @( 100  ),
            @( 200  ),
            @( 300  ),
            @( 400  ),
            @( 500  ),
            @( 600  ),
            @( 700  ),
            @( 800  ),
            @( 1600 ),
            @( 3200 ),
            @( 6400 )
        ];
    };
    
    return sZoomLevels;
}


- (BOOL) calculatedZoomsIn
{
    BOOL isAltPressed = ([NSEvent modifierFlags] & NSAlternateKeyMask) > 0;

    BOOL result = [self zoomsIn];
    if (isAltPressed) result = !result;

    return result;
}



- (void) zoom
{
    if ([self calculatedZoomsIn]) {
        [self zoomIn];
    } else {
        [self zoomOut];
    }
}


- (void) zoomIn
{
    NSInteger magnificationIndex = [self magnificationIndex];
    if (magnificationIndex < ([[self _levels] count] - 1)) magnificationIndex++;
    [self setMagnificationIndex:magnificationIndex];
}


- (void) zoomOut
{
    NSInteger magnificationIndex = [self magnificationIndex];
    if (magnificationIndex > 0) magnificationIndex--;
    [self setMagnificationIndex:magnificationIndex];
}



- (void) zoomToMagnificationLevel:(CGFloat)magnificationLevel
{
    NSInteger index = [self magnificationIndexForLevel:magnificationLevel];
    [self setMagnificationIndex:index];
}


- (CGFloat) magnificationLevel
{
    NSInteger m = [[[self _levels] objectAtIndex:_magnificationIndex] integerValue];
    return m / 100.0;
}


- (NSString *) magnificationString
{
    NSInteger m = [[[self _levels] objectAtIndex:_magnificationIndex] integerValue];
    return [NSString stringWithFormat:@"%ld%%", (long)m];
}


@end
