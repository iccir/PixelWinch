//
//  Canvas.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import "Canvas.h"

#import "CanvasObject.h"
#import "ImageDistanceMap.h"
#import "Screenshot.h"


@implementation Canvas {
    NSMutableDictionary *_groupNameToObjectsMap;
    NSMutableArray   *_hiddenGroupNames;
    ImageDistanceMap *_distanceMap;
    NSMutableArray   *_selectedObjects;
}


- (id) initWithDelegate:(id<CanvasDelegate>)delegate
{
    if ((self = [super init])) {
        _delegate   = delegate;

        _groupNameToObjectsMap = [NSMutableDictionary dictionary];
        _hiddenGroupNames = [NSMutableArray array];
        
        _undoManager = [[NSUndoManager alloc] init];
        
        _selectedObjects = [NSMutableArray array];
    }
    
    return self;
}


- (id) init
{
    return [self initWithDelegate:nil];
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) setupWithScreenshot:(Screenshot *)screenshot dictionary:(NSDictionary *)state
{
    if (_screenshot) return;
    _screenshot = screenshot;
    
    if (!screenshot) return;
    
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
    
    for (CanvasObject *object in allObjects) {
        [self addCanvasObject:object];
    }
    
    [_undoManager removeAllActions];

    _distanceMap = [[ImageDistanceMap alloc] initWithCGImage:[screenshot CGImage]];
    [_distanceMap buildMaps];
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


- (void) _restoreState:(NSDictionary *)stateToRestore ofObject:(CanvasObject *)object
{
    NSDictionary *stateToSave = [object dictionaryRepresentation];
    [[_undoManager prepareWithInvocationTarget:self] _restoreState:stateToSave ofObject:object];

    [object readFromDictionary:stateToRestore];
    
    [_delegate canvas:self didUpdateObject:object];
}


#pragma mark - Subclasses to Call

- (void) canvasObjectWillUpdate:(CanvasObject *)object
{
    if ([object participatesInUndo]) {
        NSDictionary *state = [object dictionaryRepresentation];

        [_undoManager beginUndoGrouping];
        [[_undoManager prepareWithInvocationTarget:self] _restoreState:state ofObject:object];
    }
}


- (void) canvasObjectDidUpdate:(CanvasObject *)object
{
    [_delegate canvas:self didUpdateObject:object];

    if ([object participatesInUndo]) {
        [_undoManager endUndoGrouping];
    }
}


#pragma mark - Public Methods

- (void) addCanvasObject:(CanvasObject *)object
{
    if (!object) return;

    if ([object participatesInUndo]) {
        [_undoManager registerUndoWithTarget:self selector:@selector(removeCanvasObject:) object:object];

        if (![_undoManager isUndoing]) {
            [_undoManager setActionName:NSLocalizedString(@"Add Object", nil)];
        }
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
    
    if ([_selectedObjects containsObject:object]) {
        [_selectedObjects removeObject:object];
        [_delegate canvas:self didDeselectObject:object];
    }
    
    if ([object participatesInUndo]) {
        [_undoManager registerUndoWithTarget:self selector:@selector(addCanvasObject:) object:object];

        if (![_undoManager isUndoing]) {
            [_undoManager setActionName:NSLocalizedString(@"Delete", nil)];
        }
    }

    [object setCanvas:nil];
    
    NSString *groupName = [[object class] groupName];
    [[_groupNameToObjectsMap objectForKey:groupName] removeObject:object];

    if (![self isGroupNameHidden:groupName]) {
        [_delegate canvas:self didRemoveObject:object];
    }
}


- (void) selectAllObjects
{
    NSMutableArray *objectsToSelect = [NSMutableArray array];
    
    for (CanvasObject *object in [self allCanvasObjects]) {
        if ([object isSelectable]) {
            [objectsToSelect addObject:object];
        }
    }
    
    // Select objects in geometric order (top-left to bottom-right)
    [objectsToSelect sortUsingComparator:^NSComparisonResult(id a, id b) {
        CGRect rectA = [(CanvasObject *)a rect];
        CGRect rectB = [(CanvasObject *)b rect];

        CGFloat yDelta = rectB.origin.y - rectA.origin.y;
        
        if (yDelta == 0) {
            CGFloat xDelta = rectB.origin.x - rectA.origin.x;

            if (xDelta == 0) {
                return NSOrderedSame;
            } else if (xDelta > 0) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }

        
        } else if (yDelta > 0) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];

    [self deselectAllObjects];
    for (CanvasObject *object in objectsToSelect) {
        [self selectObject:object];
    }
}


- (void) deselectAllObjects
{
    NSArray *selectedObjects = [_selectedObjects mutableCopy];

    for (CanvasObject *object in selectedObjects) {
        [self deselectObject:object];
    }
}


- (void) selectObject:(CanvasObject *)object
{
    if (![_selectedObjects containsObject:object]) {
        [_selectedObjects addObject:object];
        [_delegate canvas:self didSelectObject:object];
    }
}


- (void) deselectObject:(CanvasObject *)object
{
    if ([_selectedObjects containsObject:object]) {
        [_selectedObjects removeObject:object];
        [_delegate canvas:self didDeselectObject:object];
    }
}


- (NSArray *) canvasObjectsWithGroupName:(NSString *)inGroupName
{
    return [_groupNameToObjectsMap objectForKey:inGroupName];
}


- (NSArray *) allCanvasObjects
{
    NSMutableSet *all = [NSMutableSet set];

    for (id key in _groupNameToObjectsMap) {
        [all addObjectsFromArray:[_groupNameToObjectsMap objectForKey:key]];
    }
    
    return [all allObjects];
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
        
        [_delegate canvasDidChangeHiddenGroupNames:self];
    }
}


- (BOOL) isGroupNameHidden:(NSString *)groupName
{
    return [_hiddenGroupNames containsObject:groupName];
}


- (void) dumpDistanceMaps
{
    [_distanceMap dump];
}


#pragma mark - Accessors

- (size_t) distancePlaneWidth
{
    return [_distanceMap width];
}


- (size_t) distancePlaneHeight
{
    return [_distanceMap height];
}


- (UInt8 *) horizontalDistancePlane
{
    return [_distanceMap horizontalPlane];
}


- (UInt8 *) verticalDistancePlane
{
    return [_distanceMap verticalPlane];
}


- (NSArray *) selectedObjects
{
    return [_selectedObjects copy];
}


@end

