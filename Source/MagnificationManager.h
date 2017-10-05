//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@class CanvasView, RulerView;


@interface MagnificationManager : NSObject

@property (nonatomic, weak) CanvasView *canvasView;
@property (nonatomic, weak) RulerView  *horizontalRuler;
@property (nonatomic, weak) RulerView  *verticalRuler;

- (NSInteger) indexInArray:(NSArray *)array forMagnification:(CGFloat)inLevel;

@property (nonatomic) CGFloat magnification;

// For slider, 6%, 12%, 25%, 50%, 66%, 100-800%, 1600%, 3200%, 6400%
@property (nonatomic, strong, readonly) NSArray *levelsForZooming;

- (void) zoomIn;
- (void) zoomOut;
- (void) zoomWithDirection:(NSInteger)direction;
- (void) zoomWithDirection:(NSInteger)direction event:(NSEvent *)event;


// For slider, 6%, 12%, 25%, 50%, 66%, 100-6400%
@property (nonatomic, strong, readonly) NSArray *levelsForSlider;

@property (nonatomic, readonly) NSInteger numberOfTickMarks;
@property (nonatomic) NSInteger tickMarkPosition;

@property (nonatomic, strong, readonly) NSString *stringValue;

@end
