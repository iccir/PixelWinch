//
//  GrappleTool.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-05.
//
//

#import "GrappleTool.h"

#import "Canvas.h"
#import "CursorAdditions.h"

#import "Line.h"
#import "LineObjectView.h"
#import "CanvasObjectView.h"
#import "Guide.h"
#import "Rectangle.h"
#import "GrappleCalculator.h"
#import "ImageDistanceMap.h"


static NSString * const sVerticalKey  = @"vertical";
static NSString * const sToleranceKey = @"tolerance";


@implementation GrappleTool {
    CGPoint  _previewPoint;
    Line    *_previewGrapple;
    Guide   *_previewGuide;

    Line    *_newGrapple;

    Line    *_waitingLine;
    CGPoint  _waitingPoint;
    UInt8    _waitingThreshold;
    
    CGPoint  _downPoint;
    CGPoint  _originalPoint;
    CGPoint  _lastPoint;
}


+ (id<GrappleCalculator>) _calculator
{
    static id<GrappleCalculator> sCalculator = nil;
    
    if (!sCalculator) {
        NSArray *classes = GetClassesMatchesProtocol(@protocol(GrappleCalculator));
        sCalculator = [[classes lastObject] sharedInstance];
    }
    
    return sCalculator;
}


+ (BOOL) isEnabled
{
    return [self _calculator] != nil;
}


- (id) initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if ((self = [super initWithDictionaryRepresentation:dictionary])) {
        NSNumber *verticalNumber  = [dictionary objectForKey:sVerticalKey];
        _vertical  = !verticalNumber  || [verticalNumber  boolValue];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handlePreferencesDidChange:) name:PreferencesDidChangeNotification      object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDistanceMapReady:)     name:ImageDistanceMapReadyNotificationName object:nil];
    }
    
    return self;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) writeToDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:@(_vertical)  forKey:sVerticalKey];
}


- (NSCursor *) cursor
{
    BOOL isGuide    = [self calculatedIsGuide];
    BOOL isVertical = [self calculatedIsVertical];
    
    if (isGuide) {
        return isVertical ? [NSCursor resizeLeftRightCursor] : [NSCursor resizeUpDownCursor];
    } else {
        return isVertical ? [NSCursor winch_grappleVerticalCursor] : [NSCursor winch_grappleHorizontalCursor];
    }
}


- (NSString *) name
{
    return @"grapple";
}


- (unichar) shortcutKey
{
    return 'g';
}


- (BOOL) calculatedIsVertical
{
    BOOL isAltPressed = ([NSEvent modifierFlags] & NSAlternateKeyMask) > 0;

    BOOL result = [self isVertical];
    if (isAltPressed) result = !result;

    return result;
}


- (BOOL) calculatedIsGuide
{
    return ([NSEvent modifierFlags] & NSCommandKeyMask) > 0;
}


- (void) updatePreviewGrapple
{
    Canvas *canvas = [[self owner] canvas];

    if (![[self owner] isToolSelected:self] || isnan(_previewPoint.x)) {
        [self _removePreviewGrapple];
        [self _removePreviewGuide];
        return;
    }

    BOOL isVertical = [self calculatedIsVertical];
    BOOL isGuide    = [self calculatedIsGuide];

    if (isGuide) {
        if ([_previewGuide isVertical] != isVertical) {
            [canvas removeCanvasObject:_previewGuide];
            _previewGuide = nil;
        }
    
        [self _removePreviewGrapple];

        if (!_previewGuide) {
            _previewGuide = [Guide guideVertical:isVertical];
            [_previewGuide setParticipatesInUndo:NO];
            [_previewGuide setPersistent:NO];

            [canvas addCanvasObject:_previewGuide];
        }

        CGPoint point = _previewPoint;
        [_previewGuide setOffset:floor(isVertical ? point.x : point.y)];

        return;
  
    } else {
        [self _removePreviewGuide];

        if ([_previewGrapple isVertical] != isVertical) {
            // Call this directly, don't use -_removePreviewGrapple as it nils our text
            [canvas removeCanvasObject:_previewGrapple];
            _previewGrapple = nil;
        }

        if (!_previewGrapple) {
            _previewGrapple = [Line lineVertical:isVertical];
            [_previewGrapple setParticipatesInUndo:NO];
            [_previewGrapple setPersistent:NO];
            [_previewGrapple setPreview:YES];

            [canvas addCanvasObject:_previewGrapple];
        }
        
        CGPoint point = _previewPoint;
        [self _updateLine:_previewGrapple point:point threshold:0];

        if (![_previewGrapple length]) {
            [self _removePreviewGrapple];
            return;
        }

        NSString *previewText = GetStringForFloat([_previewGrapple length]);
        [[CursorInfo sharedInstance] setText:previewText forKey:@"preview-grapple"];
    }
}


- (void) toggleVertical
{
    [self setVertical:![self isVertical]];
    [self updatePreviewGrapple];
}


#pragma mark - Private Methods

- (void) _updateLastPreviewGrapplePointWithCurrentMouseLocation
{
    CanvasView *canvasView = [[self owner] canvasView];

    CGPoint point = CGPointMake(NAN, NAN);
    if ([canvasView convertMouseLocationToCanvasPoint:&point]) {
        _previewPoint = point;
    }
}


- (void) _handlePreferencesDidChange:(NSNotification *)note
{
    [self updatePreviewGrapple];
}


- (void) _handleDistanceMapReady:(NSNotification *)note
{
    if (_waitingLine) {
        [self _updateLine:_waitingLine point:_waitingPoint threshold:_waitingThreshold];
    }

    [self updatePreviewGrapple];
}


- (CGPoint) _canvasPointForEvent:(NSEvent *)event
{
    return [[[self owner] canvasView] canvasPointForEvent:event];
}


- (void) _updateLine:(Line *)line point:(CGPoint)point threshold:(UInt8)threshold
{
    Canvas *canvas = [[self owner] canvas];
    UInt8  *horizontalPlane = [canvas horizontalDistancePlane];
    UInt8  *verticalPlane   = [canvas verticalDistancePlane];

    size_t planeWidth  = [canvas distancePlaneWidth];
    size_t planeHeight = [canvas distancePlaneHeight];

    id<GrappleCalculator> calculator = [[self class] _calculator];
    
    if (!verticalPlane || !horizontalPlane || !calculator) {
        _waitingLine = line;
        _waitingPoint = point;
        _waitingThreshold = threshold;
        return;
    }

    if (point.x < 0 ||
        point.y < 0 ||
        point.x >= planeWidth ||
        point.y >= planeHeight)
    {
        return;
    }

    _waitingLine = nil;

    NSString *guidesGroupName     = [Guide groupName];
    NSString *rectanglesGroupName = [Rectangle groupName];

    NSArray *guides        = [canvas canvasObjectsWithGroupName:guidesGroupName];
    NSArray *rectangles    = [canvas canvasObjectsWithGroupName:rectanglesGroupName];
    
    BOOL stopsOnGuides     = ![canvas isGroupNameHidden:guidesGroupName];
    BOOL stopsOnRectangles = ![canvas isGroupNameHidden:rectanglesGroupName];
    
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        stopsOnGuides = stopsOnRectangles = NO;
    }
    
    NSUInteger maxCutCount = ([rectangles count] * 2) + ([guides count]);
    NSInteger  cutCount    = 0;
    CGFloat   *cutOffsets  = maxCutCount ? malloc(sizeof(CGFloat) * maxCutCount) : NULL;
   
    if ([line isVertical]) {
        point.x = floor(point.x);
        point.y = floor(point.y);
    
        size_t y1 = 0, y2 = 0;
        [calculator calculateVerticalGrappleWithPlane: verticalPlane
                                           planeWidth: planeWidth
                                          planeHeight: planeHeight
                                               startX: point.x
                                               startY: point.y
                                            threshold: threshold
                                                outY1: &y1
                                                outY2: &y2];

        if (cutOffsets && stopsOnGuides) {
            for (Guide *guide in guides) {
                if (![guide isVertical]) {
                    cutOffsets[cutCount++] = [guide offset];
                }
            }
        }

        if (cutOffsets && stopsOnRectangles) {
            for (CanvasObject *rectangle in rectangles) {
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
        [line setRect:rect];

    } else {
        point.x = floor(point.x);
        point.y = floor(point.y);
    
        size_t x1 = 0, x2 = 0;
        [calculator calculateHorizontalGrappleWithPlane: horizontalPlane
                                             planeWidth: planeWidth
                                            planeHeight: planeHeight
                                                 startX: point.x
                                                 startY: point.y
                                              threshold: threshold
                                                  outX1: &x1
                                                  outX2: &x2];

        if (cutOffsets && stopsOnGuides) {
            for (Guide *guide in guides) {
                if ([guide isVertical]) {
                    cutOffsets[cutCount++] = [guide offset];
                }
            }
        }
        
        if (cutOffsets && stopsOnRectangles) {
            for (CanvasObject *rectangle in rectangles) {
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
        [line setRect:rect];
    }
    
    free(cutOffsets);
}


- (void) _removePreviewGuide
{
    if (_previewGuide) {
        [[[self owner] canvas] removeCanvasObject:_previewGuide];
        _previewGuide = nil;
    }
}


- (void) _removePreviewGrapple
{
    [[CursorInfo sharedInstance] setText:nil forKey:@"preview-grapple"];

    if (_previewGrapple) {
        [[[self owner] canvas] removeCanvasObject:_previewGrapple];
        _previewGrapple = nil;
    }
}


- (void) _updateNewGrappleWithEvent:(NSEvent *)event
{
    CGPoint currentPoint = [event locationInWindow];
    if ([event type] == NSFlagsChanged) {
        currentPoint = _lastPoint;
    } else {
        _lastPoint = currentPoint;
    }

    CGFloat xDelta = currentPoint.x - _downPoint.x;
    CGFloat yDelta = currentPoint.y - _downPoint.y;
    
    NSInteger threshold = (xDelta > yDelta) ? xDelta : yDelta;
    
    if (threshold < 0) threshold = 0;
    else if (threshold > 255) threshold = 255;

    NSString *cursorText = nil;

    [self _updateLine:_newGrapple point:_originalPoint threshold:threshold];

    if (threshold) {
        CGFloat percent = round((threshold / 255.0f) * 100);
        cursorText = [NSString stringWithFormat:@"%@ %C %g%%", GetStringForFloat([_newGrapple length]), (unichar)0x2014, percent];
    } else {
        cursorText = GetStringForFloat([_newGrapple length]);
    }
        
    [[CursorInfo sharedInstance] setText:cursorText forKey:@"new-grapple"];
}


- (BOOL) canSelectCanvasObject:(CanvasObject *)object
{
    return [object isKindOfClass:[Line class]];
}


#pragma mark - Events

- (void) flagsChangedWithEvent:(NSEvent *)event
{
    if (_newGrapple) {
        [self _updateNewGrappleWithEvent:event];
    } else {
        [self updatePreviewGrapple];
    }
}


- (void) mouseMovedWithEvent:(NSEvent *)event
{
    // The grapple calculator uses floor() on the point, so pass in raw points rather
    // than rounding
    //
    _previewPoint = [self _canvasPointForEvent:event];
    [self updatePreviewGrapple];
}


- (void) mouseExitedWithEvent:(NSEvent *)event
{
    _previewPoint = NSMakePoint(NAN, NAN);
    [self updatePreviewGrapple];
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    BOOL isVertical = [self calculatedIsVertical];
    BOOL isGuide    = [self calculatedIsGuide];

    if (isGuide && _previewGuide) {
        Guide *guide = [Guide guideVertical:isVertical];

        [guide setOffset:[_previewGuide offset]];

        [[[self owner] canvas] addCanvasObject:guide];

        [self _removePreviewGrapple];

    } else {
        [self _removePreviewGrapple];
        [self _removePreviewGuide];

        _downPoint     = [event locationInWindow];
        _originalPoint = [self _canvasPointForEvent:event];

        _newGrapple = [Line lineVertical:isVertical];

        [[[self owner] canvas] addCanvasObject:_newGrapple];

        CanvasObjectView *view = [[self owner] viewForCanvasObject:_newGrapple];
        [view setNewborn:YES];

        [view startTrackingWithEvent:event point:_originalPoint];

        [self _updateNewGrappleWithEvent:event];
    }

    return YES;
}


- (void) mouseDraggedWithEvent:(NSEvent *)event
{
    if (_newGrapple) {
        [self _updateNewGrappleWithEvent:event];
    }
}


- (void) mouseUpWithEvent:(NSEvent *)event
{
    if (_newGrapple) {
        [self _updateNewGrappleWithEvent:event];

        CanvasObjectView *view = [[self owner] viewForCanvasObject:_newGrapple];
        [view endTrackingWithEvent:event point:[self _canvasPointForEvent:event]];
        [view setNewborn:NO];

        [[CursorInfo sharedInstance] setText:nil forKey:@"new-grapple"];

        _newGrapple = nil;
    }
}


- (void) reset
{
    [super reset];
    [self _removePreviewGrapple];
    _previewPoint = CGPointMake(NAN, NAN);
}


- (void) canvasWindowDidAppear
{
    if ([[self owner] isToolSelected:self]) {
        [self _updateLastPreviewGrapplePointWithCurrentMouseLocation];
        [self updatePreviewGrapple];
    }
}


- (void) didSelect
{
    [self _updateLastPreviewGrapplePointWithCurrentMouseLocation];
    [self updatePreviewGrapple];
}


- (void) didDeselect
{
    [self reset];
    [self updatePreviewGrapple];
}


@end
