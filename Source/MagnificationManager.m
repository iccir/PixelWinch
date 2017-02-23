//
//  MagnificationManager.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-11-12.
//
//

#import "MagnificationManager.h"

#import "CanvasView.h"
#import "RulerView.h"


@implementation MagnificationManager {
    NSArray *_levelsForZooming;
    NSArray *_levelsForSlider;
}


+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    NSArray *affectingKeys = nil;

    if ([key isEqualToString:@"tickMarkPosition"]) {
        affectingKeys = @[ @"magnification" ];
    
    } else if ([key isEqualToString:@"stringValue"]) {
        affectingKeys = @[ @"magnification" ];
    }
    
    if (affectingKeys) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    
    return keyPaths;
}


- (NSInteger) indexInArray:(NSArray *)array forMagnification:(CGFloat)inLevel
{
    NSInteger index = [array count] - 1;
    for (NSNumber *levelNumber in [array reverseObjectEnumerator]) {
        if ([levelNumber doubleValue] <= inLevel) {
            return index;
        }

        index--;
    }
    
    return 0;
}


- (void) zoomWithDirection:(NSInteger)direction event:(NSEvent *)event
{
    NSArray *levels = [self levelsForZooming];
    
    NSInteger index = [self indexInArray:levels forMagnification:_magnification];
    index += direction;
    
    if (index < 0) return;
    if (index >= [levels count]) return;

    CGFloat magnification = [[levels objectAtIndex:index] doubleValue];

    CGPoint point;
    if (event) {
        point = [_canvasView canvasPointForEvent:event];
    } else {
        point = [_canvasView canvasPointAtCenter];
    }

    [_canvasView setMagnification:magnification centeredAtCanvasPoint:point];

    [self setMagnification:magnification];
}


- (void) zoomWithDirection:(NSInteger)direction
{
    [self zoomWithDirection:direction event:nil];
}


- (void) zoomIn
{
    [self zoomWithDirection:1 event:nil];
}


- (void) zoomOut
{
    [self zoomWithDirection:-1 event:nil];
}


#pragma mark -
#pragma mark Accessors

- (void) setCanvasView:(CanvasView *)canvasView
{
    if (_canvasView != canvasView) {
        _canvasView = canvasView;
        [_canvasView setMagnification:_magnification];
    }
}

- (void) setMagnification:(CGFloat)magnification
{
    _magnification = magnification;

    [_canvasView      setMagnification:magnification];
    [_horizontalRuler setMagnification:magnification];
    [_verticalRuler   setMagnification:magnification];
}


- (void) setTickMarkPosition:(NSInteger)tickMarkPosition
{
    NSArray *levels = [self levelsForSlider];
    double level = [[levels objectAtIndex:tickMarkPosition] doubleValue];
    [self setMagnification:level];
}


- (NSInteger) tickMarkPosition
{
    NSArray *levels = [self levelsForSlider];
    return [self indexInArray:levels forMagnification:_magnification];
}


- (NSArray *) levelsForZooming
{
    if (!_levelsForZooming) {
        _levelsForZooming = @[
            @( 0.25 ),
            @( 0.50 ),
            @( 0.66 ),
            @( 1    ),
            @( 2    ),
            @( 3    ),
            @( 4    ),
            @( 5    ),
            @( 6    ),
            @( 7    ),
            @( 8    ),
            @( 16   ),
            @( 32   ),
            @( 64   )
        ];
    }
    
    return _levelsForZooming;
}


- (NSArray *) levelsForSlider
{
    if (!_levelsForSlider) {
        NSMutableArray *levels = [NSMutableArray array];
        
        [levels addObjectsFromArray:@[
            @( 0.25 ),
            @( 0.50 ),
            @( 0.66 )
        ]];

        for (NSInteger i = 1; i <= 64; i+=1) {
            [levels addObject:@( (double)i )];
        }
        
        _levelsForSlider = levels;
    };
    
    return _levelsForSlider;
}


- (NSString *) stringValue
{
    NSInteger m = [self magnification] * 100;
    return [NSString stringWithFormat:@"%ld%%", (long)m];
}


- (NSInteger) numberOfMagnificationTickMarks
{
    NSArray *levels = [self levelsForSlider];
    return [levels count];
}


@end
