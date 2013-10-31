//
//  Canvas.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "Canvas.h"

#import "Grapple.h"
#import "Guide.h"
#import "Marquee.h"
#import "Rectangle.h"
#import "Screenshot.h"

#import "GrappleCalculator.h"


static NSString * const sGuidesKey     = @"guides";
static NSString * const sGrapplesKey   = @"grapples";
static NSString * const sRectanglesKey = @"rectangles";



@implementation Canvas {
    NSMutableArray *_guides;
    NSMutableArray *_grapples;
    NSMutableArray *_rectangles;

    GrappleCalculator *_grappleCalculator;
    
    Grapple *_waitingGrapple;
    CGPoint  _waitingGrapplePoint;
    UInt8    _waitingGrappleThreshold;
}


- (id) initWithDelegate:(id<CanvasDelegate>)delegate
{
    if ((self = [super init])) {
        _delegate   = delegate;
        _guides     = [NSMutableArray array];
        _rectangles = [NSMutableArray array];
        _grapples   = [NSMutableArray array];

        _undoManager = [[NSUndoManager alloc] init];
        
        _grapplesStopOnGuides     = YES;
        _grapplesStopOnRectangles = YES;
    }
    
    return self;
}


- (id) init
{
    return [self initWithDelegate:nil];
}


- (void) setupWithScreenshot:(Screenshot *)screenshot dictionary:(NSDictionary *)dictionary
{
    if (_screenshot) return;
    _screenshot = screenshot;
    
    if (screenshot) {
        _size = [_screenshot size];
    }

    void (^withArrayOfDictionaries)(NSString *key, void (^block)(NSDictionary *)) = ^(NSString *key, void (^block)(NSDictionary *)) {
        NSArray *array = [dictionary objectForKey:key];
        
        if ([array isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dictionary in array) {
                if ([dictionary isKindOfClass:[NSDictionary class]]) {
                    block(dictionary);
                }
            }
        }
    };

    withArrayOfDictionaries( sGuidesKey, ^(NSDictionary *d) {
        Guide *guide = [[Guide alloc] initWithDictionaryRepresentation:d];
        if (guide) [_guides addObject:guide];
    });

    withArrayOfDictionaries( sGrapplesKey, ^(NSDictionary *d) {
        Grapple *grapple = [[Grapple alloc] initWithDictionaryRepresentation:d];
        if (grapple) [_grapples addObject:grapple];
    });

    withArrayOfDictionaries( sRectanglesKey, ^(NSDictionary *d) {
        Rectangle *rectangle = [[Rectangle alloc] initWithDictionaryRepresentation:d];
        if (rectangle) [_rectangles addObject:rectangle];
    });
    
    NSMutableArray *allObjects = [NSMutableArray array];
    [allObjects addObjectsFromArray:_guides];
    [allObjects addObjectsFromArray:_grapples];
    [allObjects addObjectsFromArray:_rectangles];
    
    for (CanvasObject *object in allObjects) {
        [object setCanvas:self];
        [self _didAddObject:object];
    }
    
    [_undoManager removeAllActions];
}


- (NSDictionary *) dictionaryRepresentation
{
    NSMutableArray *guideArray     = [NSMutableArray array];
    NSMutableArray *rectangleArray = [NSMutableArray array];
    NSMutableArray *grappleArray   = [NSMutableArray array];
    
    for (Guide *guide in _guides) {
        NSDictionary *dictionary = [guide dictionaryRepresentation];
        if (dictionary) [guideArray addObject:dictionary];
    }
    
    for (Grapple *grapple in _grapples) {
        if ([grapple isPreview]) continue;
        NSDictionary *dictionary = [grapple dictionaryRepresentation];
        if (dictionary) [grappleArray addObject:dictionary];
    }
    
    for (Rectangle *rectangle in _rectangles) {
        NSDictionary *dictionary = [rectangle dictionaryRepresentation];
        if (dictionary) [rectangleArray addObject:dictionary];
    }
    
    return @{
        sGuidesKey: guideArray,
        sGrapplesKey: grappleArray,
        sRectanglesKey: rectangleArray
    };
}


#pragma mark - Objects

- (void) _restoreState:(NSDictionary *)stateToRestore ofObject:(CanvasObject *)object
{
    NSDictionary *stateToSave = [object dictionaryRepresentation];
    [[_undoManager prepareWithInvocationTarget:self] _restoreState:stateToSave ofObject:object];

    [object readFromDictionary:stateToRestore];
    
    [_delegate canvas:self didUpdateObject:object];
}


- (void) _didAddObject:(CanvasObject *)object
{
    [_delegate canvas:self didAddObject:object];
}


- (void) _didRemoveObject:(CanvasObject *)object
{
    [_delegate canvas:self didRemoveObject:object];
}


- (void) objectWillUpdate:(CanvasObject *)object
{
    if (object == _previewGrapple) return;

    NSDictionary *state = [object dictionaryRepresentation];

    [_undoManager beginUndoGrouping];
    [[_undoManager prepareWithInvocationTarget:self] _restoreState:state ofObject:object];
}


- (void) objectDidUpdate:(CanvasObject *)object
{
    [_delegate canvas:self didUpdateObject:object];

    if (object == _previewGrapple) return;
    [_undoManager endUndoGrouping];
}


- (void) removeObject:(CanvasObject *)object
{
    if ([object isKindOfClass:[Guide class]]) {
        [self removeGuide:(Guide *)object];

    } else if ([object isKindOfClass:[Grapple class]]) {
        if (object == _previewGrapple) {
            [self removePreviewGrapple];
        } else {
            [self removeGrapple:(Grapple *)object];
        }

    } else if ([object isKindOfClass:[Rectangle class]]) {
        [self removeRectangle:(Rectangle *)object];
    }
}


#pragma mark - Guides

- (Guide *) makeGuideVertical:(BOOL)vertical
{
    Guide *guide = [Guide guideWithOffset:-INFINITY vertical:vertical];
    [self _addGuide:guide];
    return guide;
}


- (void) _addGuide:(Guide *)guide
{
    if (!guide) return;

    [_undoManager registerUndoWithTarget:self selector:@selector(removeGuide:) object:guide];
    [_undoManager setActionName:NSLocalizedString(@"Add Guide", nil)];

    [guide setCanvas:self];
    [_guides addObject:guide];

    [self _didAddObject:guide];
}


- (void) removeGuide:(Guide *)guide
{
    if (!guide) return;

    [_undoManager registerUndoWithTarget:self selector:@selector(_addGuide:) object:guide];
    [_undoManager setActionName:NSLocalizedString(@"Remove Guide", nil)];

    [guide setCanvas:nil];
    [_guides removeObject:guide];
    [self _didRemoveObject:guide];
}


#pragma mark - Grapples

- (GrappleCalculator *) grappleCalculator
{
    if (!_grappleCalculator) {
        _grappleCalculator = [[GrappleCalculator alloc] initWithCanvas:self];
    }
    
    return _grappleCalculator;
}


- (void) _grappleCalculatorReady
{
    if (_waitingGrapple) {
        [self updateGrapple:_waitingGrapple point:_waitingGrapplePoint threshold:_waitingGrappleThreshold];

        _waitingGrapple = nil;
        _waitingGrapplePoint = CGPointZero;
        _waitingGrappleThreshold = 0;
    }
}


- (void) _addGrapple:(Grapple *)grapple
{
    if ([grapple isPreview]) {
        _previewGrapple = grapple;

    } else {
        [_undoManager registerUndoWithTarget:self selector:@selector(removeGrapple:) object:grapple];
        [_undoManager setActionName:NSLocalizedString(@"Add Grapple", nil)];
    
        [_grapples addObject:grapple];
    }

    [grapple setCanvas:self];
    [self _didAddObject:grapple];
}


- (Grapple *) _makeGrappleVertical:(BOOL)vertical preview:(BOOL)preview
{
    Grapple *grapple = [Grapple grappleVertical:vertical];
    [grapple setPreview:preview];

    [self _addGrapple:grapple];

    return grapple;
}


- (Grapple *) makeGrappleVertical:(BOOL)vertical
{
    return [self _makeGrappleVertical:vertical preview:NO];
}


- (void) removeGrapple:(Grapple *)grapple
{
    if (!grapple) return;

    if (![grapple isPreview]) {
        [_undoManager registerUndoWithTarget:self selector:@selector(_addGrapple:) object:grapple];
        [_undoManager setActionName:NSLocalizedString(@"Remove Grapple", nil)];
    }

    [grapple setCanvas:nil];
    [_grapples removeObject:grapple];
    [self _didRemoveObject:grapple];
}


- (Grapple *) makePreviewGrappleVertical:(BOOL)vertical
{
    return [self _makeGrappleVertical:vertical preview:YES];
}


- (void) removePreviewGrapple
{
    if (!_previewGrapple) return;

    Grapple *grapple = _previewGrapple;
    _previewGrapple = nil;
    [self _didRemoveObject:grapple];
}


- (void) updateGrapple:(Grapple *)grapple point:(CGPoint)point threshold:(UInt8)threshold
{
    if (!grapple) return;

    GrappleCalculator *calculator = [self grappleCalculator];
    if (![calculator isReady]) {
        [calculator prepare];

        _waitingGrapple = grapple;
        _waitingGrapplePoint = point;
        _waitingGrappleThreshold = threshold;

        return;
    }

    NSUInteger maxCutCount = ([_rectangles count] * 2) + [_guides count];
    NSInteger  cutCount    = 0;
    CGFloat   *cutOffsets  = maxCutCount ? malloc(sizeof(CGFloat) * maxCutCount) : NULL;

    if ([grapple isVertical]) {
        point.x = floor(point.x) + 0.5;
        point.y = floor(point.y);
    
        size_t y1, y2;
        [calculator calculateVerticalGrappleWithStartX: point.x
                                                startY: point.y
                                             threshold: threshold
                                                 outY1: &y1
                                                 outY2: &y2];

        if (_grapplesStopOnGuides) {
            for (Guide *guide in _guides) {
                if (![guide isVertical]) {
                    cutOffsets[cutCount++] = [guide offset];
                }
            }
        }

        if (_grapplesStopOnRectangles) {
            for (Rectangle *rectangle in _rectangles) {
                CGRect rect = [rectangle rect];

                if ((point.x >= rect.origin.x) && (point.x < CGRectGetMaxX(rect))) {
                    cutOffsets[cutCount++] = CGRectGetMinY(rect);
                    cutOffsets[cutCount++] = CGRectGetMaxY(rect);
                }
            }
        }

        for (NSInteger i = 0; i < cutCount; i++) {
            CGFloat cutOffset = cutOffsets[i];

            if (cutOffset < point.y && cutOffset > y1) {
                y1 = cutOffset;
            } else if (cutOffset >= point.y && cutOffset < y2) {
                y2 = cutOffset;
            }
        }
        
        CGRect rect = CGRectMake(point.x, y1, 0, y2 - y1);
        [grapple setRect:rect];

    } else {
        point.x = floor(point.x);
        point.y = floor(point.y) + 0.5;
    
        size_t x1, x2;
        [calculator calculateHorizontalGrappleWithStartX: point.x
                                                  startY: point.y
                                               threshold: threshold
                                                   outX1: &x1
                                                   outX2: &x2];

        if (_grapplesStopOnGuides) {
            for (Guide *guide in _guides) {
                if ([guide isVertical]) {
                    cutOffsets[cutCount++] = [guide offset];
                }
            }
        }
        
        if (_grapplesStopOnRectangles) {
            for (Rectangle *rectangle in _rectangles) {
                CGRect rect = [rectangle rect];

                if ((point.y >= rect.origin.y) && (point.y < CGRectGetMaxY(rect))) {
                    cutOffsets[cutCount++] = CGRectGetMinX(rect);
                    cutOffsets[cutCount++] = CGRectGetMaxX(rect);
                }
            }
        }

        for (NSInteger i = 0; i < cutCount; i++) {
            CGFloat cutOffset = cutOffsets[i];

            if (cutOffset < point.x && cutOffset > x1) {
                x1 = cutOffset;
            } else if (cutOffset >= point.x && cutOffset < x2) {
                x2 = cutOffset;
            }
        }
        
        CGRect rect = CGRectMake(x1, point.y, x2 - x1, 0);
        [grapple setRect:rect];
    }
    
    free(cutOffsets);
}


#pragma mark - Rectangles

- (Rectangle *) makeRectangle
{
    Rectangle *rectangle = [Rectangle rectangle];
    [self _addRectangle:rectangle];
    return rectangle;
}


- (void) _addRectangle:(Rectangle *)rectangle
{
    if (!rectangle) return;

    [_undoManager registerUndoWithTarget:self selector:@selector(removeRectangle:) object:rectangle];
    [_undoManager setActionName:NSLocalizedString(@"Add Rectangle", nil)];

    [rectangle setCanvas:self];
    [_rectangles addObject:rectangle];

    [self _didAddObject:rectangle];
}


- (void) removeRectangle:(Rectangle *)rectangle
{
    if (!rectangle) return;

    [_undoManager registerUndoWithTarget:self selector:@selector(_addRectangle:) object:rectangle];
    [_undoManager setActionName:NSLocalizedString(@"Remove Rectangle", nil)];

    [rectangle setCanvas:nil];
    [_rectangles removeObject:rectangle];
    [self _didRemoveObject:rectangle];
}


#pragma mark - Marquee

- (void) clearMarquee
{
    Marquee *marquee = _marquee;

    if (marquee) {
        _marquee = nil;
        
        if (!_marqueeHidden) {
            [self _didRemoveObject:marquee];
        }
    }
}


- (Marquee *) makeMarquee
{
    [self clearMarquee];
    _marquee = [[Marquee alloc] init];
    [_marquee setCanvas:self];

    if (!_marqueeHidden) {
        [self _didAddObject:_marquee];
    }
    
    return _marquee;
}


- (void) setMarqueeHidden:(BOOL)marqueeHidden
{
    if (_marqueeHidden != marqueeHidden) {
        _marqueeHidden = marqueeHidden;
        
        if (_marquee) {
            if (_marqueeHidden) {
                [self _didRemoveObject:_marquee];
            } else {
                [self _didAddObject:_marquee];
            }
        }
    }
}



@end
