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
    NSMutableDictionary *_groupNameToObjectsMap;
    NSMutableArray *_hiddenGroupNames;

    GrappleCalculator *_grappleCalculator;
    
    Grapple *_waitingGrapple;
    CGPoint  _waitingGrapplePoint;
    UInt8    _waitingGrappleThreshold;
}


- (id) initWithDelegate:(id<CanvasDelegate>)delegate
{
    if ((self = [super init])) {
        _delegate   = delegate;

        _groupNameToObjectsMap = [NSMutableDictionary dictionary];
        _hiddenGroupNames = [NSMutableArray array];
        
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


- (void) setupWithScreenshot:(Screenshot *)screenshot dictionary:(NSDictionary *)state
{
    if (_screenshot) return;
    _screenshot = screenshot;
    
    if (screenshot) {
        _size = [_screenshot size];
    }

    NSMutableArray *allObjects = [NSMutableArray array];

    if ([state isKindOfClass:[NSDictionary class]] && [state count]) {
        for (NSString *groupName in state) {
            if (![groupName isKindOfClass:[NSString class]]) continue;
            
            for (NSDictionary *dictionaryRepresentation in [state objectForKey:groupName]) {
                if (![dictionaryRepresentation isKindOfClass:[NSDictionary class]]) {
                    continue;
                }

                CanvasObject *object = [CanvasObject canvasObjectWithGroupName:groupName dictionaryRepresentation:dictionaryRepresentation];
                if (object) [allObjects addObject:object];
            }
        }
    }
    
    NSLog(@"%@ %@", state, allObjects);
    
    for (CanvasObject *object in allObjects) {

        [self addCanvasObject:object];
//        [object setCanvas:self];
//        [_delegate canvas:self didAddObject:object];
    }
    
    [_undoManager removeAllActions];
}


- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    for (id groupName in _groupNameToObjectsMap) {
        NSArray        *inObjects  = [_groupNameToObjectsMap objectForKey:groupName];
        NSMutableArray *outObjects = [NSMutableArray arrayWithCapacity:[inObjects count]];

        for (CanvasObject *object in inObjects) {
            if ([object isPersistent]) {
                [outObjects addObject:[object dictionaryRepresentation]];
            }
        }
        
        if ([outObjects count]) {
            [result setObject:outObjects forKey:groupName];
        }
    }

    return result;
}


#pragma mark - Objects

- (void) _restoreState:(NSDictionary *)stateToRestore ofObject:(CanvasObject *)object
{
    NSDictionary *stateToSave = [object dictionaryRepresentation];
    [[_undoManager prepareWithInvocationTarget:self] _restoreState:stateToSave ofObject:object];

    [object readFromDictionary:stateToRestore];
    
    [_delegate canvas:self didUpdateObject:object];
}


- (void) canvasObjectWillUpdate:(CanvasObject *)object
{
    if (object == _previewGrapple) return;

    NSDictionary *state = [object dictionaryRepresentation];

    [_undoManager beginUndoGrouping];
    [[_undoManager prepareWithInvocationTarget:self] _restoreState:state ofObject:object];
}


- (void) canvasObjectDidUpdate:(CanvasObject *)object
{
    [_delegate canvas:self didUpdateObject:object];

    if (object == _previewGrapple) return;
    [_undoManager endUndoGrouping];
}


- (void) addCanvasObject:(CanvasObject *)object
{
    if (!object) return;

    if ([object participatesInUndo]) {
        [_undoManager registerUndoWithTarget:self selector:@selector(removeCanvasObject:) object:object];
        [_undoManager setActionName:NSLocalizedString(@"Add Object", nil)];
    }

    [object setCanvas:self];

    NSString *groupName = [[object class] groupName];
    NSMutableArray *objects = [_groupNameToObjectsMap objectForKey:groupName];

    if (!objects) {
        objects = [NSMutableArray array];
        [_groupNameToObjectsMap setObject:objects forKey:groupName];
    }

    [objects addObject:object];

    if (![self isGroupNameHidden:groupName]) {
        [_delegate canvas:self didAddObject:object];
    }
}


- (void) removeCanvasObject:(CanvasObject *)object
{
    if (!object) return;
    
    if ([object participatesInUndo]) {
        [_undoManager registerUndoWithTarget:self selector:@selector(addCanvasObject:) object:object];
        [_undoManager setActionName:NSLocalizedString(@"Remove Object", nil)];
    }

    [object setCanvas:nil];
    
    NSString *groupName = [[object class] groupName];
    [[_groupNameToObjectsMap objectForKey:groupName] removeObject:object];

    if (![self isGroupNameHidden:groupName]) {
        [_delegate canvas:self didRemoveObject:object];
    }
}


- (NSArray *) canvasObjectsWithGroupName:(NSString *)inGroupName
{
    return [_groupNameToObjectsMap objectForKey:inGroupName];
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

//
//
//- (Grapple *) _makeGrappleVertical:(BOOL)vertical preview:(BOOL)preview
//{
//    Grapple *grapple = [Grapple grappleVertical:vertical];
//    [grapple setPreview:preview];
//
//    [self _addGrapple:grapple];
//
//    return grapple;
//}
//
////
//
//
//- (void) removePreviewGrapple
//{
//    if (!_previewGrapple) return;
//
//    Grapple *grapple = _previewGrapple;
//    _previewGrapple = nil;
//    [self _didRemoveObject:grapple];
//}


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

    NSArray *guides     = [self canvasObjectsWithGroupName:[Guide groupName]];
    NSArray *rectangles = [self canvasObjectsWithGroupName:[Rectangle groupName]];

    NSUInteger maxCutCount = ([rectangles count] * 2) + ([guides count]);
    NSInteger  cutCount    = 0;
    CGFloat   *cutOffsets  = maxCutCount ? malloc(sizeof(CGFloat) * maxCutCount) : NULL;
   
    if ([grapple isVertical]) {
        point.x = floor(point.x);
        point.y = floor(point.y);
    
        size_t y1, y2;
        [calculator calculateVerticalGrappleWithStartX: point.x
                                                startY: point.y
                                             threshold: threshold
                                                 outY1: &y1
                                                 outY2: &y2];

        if (_grapplesStopOnGuides) {
            for (Guide *guide in guides) {
                if (![guide isVertical]) {
                    cutOffsets[cutCount++] = [guide offset];
                }
            }
        }

        if (_grapplesStopOnRectangles) {
            for (Rectangle *rectangle in rectangles) {
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
        
        CGRect rect = CGRectMake(point.x, y1, 1, y2 - y1);
        [grapple setRect:rect];

    } else {
        point.x = floor(point.x);
        point.y = floor(point.y);
    
        size_t x1, x2;
        [calculator calculateHorizontalGrappleWithStartX: point.x
                                                  startY: point.y
                                               threshold: threshold
                                                   outX1: &x1
                                                   outX2: &x2];

        if (_grapplesStopOnGuides) {
            for (Guide *guide in guides) {
                if ([guide isVertical]) {
                    cutOffsets[cutCount++] = [guide offset];
                }
            }
        }
        
        if (_grapplesStopOnRectangles) {
            for (Rectangle *rectangle in rectangles) {
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
        
        CGRect rect = CGRectMake(x1, point.y, x2 - x1, 1);
        [grapple setRect:rect];
    }
    
    free(cutOffsets);
}


- (void) setGroupName:(NSString *)groupName hidden:(BOOL)hidden
{
    if (!groupName) return;

    BOOL isHidden = [self isGroupNameHidden:groupName];

    if (isHidden != hidden) {
        if (hidden) {
            [_hiddenGroupNames addObject:groupName];
        } else {
            [_hiddenGroupNames removeObject:groupName];
        }

        for (CanvasObject *object in [self canvasObjectsWithGroupName:groupName]) {
            if (hidden) {
                [_delegate canvas:self didRemoveObject:object];
            } else {
                [_delegate canvas:self didAddObject:object];
            }
        }
    }
}


- (BOOL) isGroupNameHidden:(NSString *)groupName
{
    return [_hiddenGroupNames containsObject:groupName];
}


@end
