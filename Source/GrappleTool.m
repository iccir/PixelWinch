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
    CGPoint  _lastPreviewGrapplePoint;
    Line    *_previewGrapple;
    Line    *_newGrapple;

    Line    *_waitingLine;
    CGPoint  _waitingPoint;
    UInt8    _waitingThreshold;
    
    CGPoint  _downPoint;
    CGPoint  _originalPoint;
    UInt8    _originalThreshold;
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
//        NSNumber *toleranceNumber = [dictionary objectForKey:sToleranceKey];

        _vertical  = !verticalNumber  || [verticalNumber  boolValue];
//        _tolerance = [toleranceNumber integerValue];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDistanceMapReady:) name:ImageDistanceMapReadyNotificationName object:nil];
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
//    [dictionary setObject:@(_tolerance) forKey:sToleranceKey];
}


- (NSCursor *) cursor
{
    return [self calculatedIsVertical] ? [NSCursor winch_grappleVerticalCursor] : [NSCursor winch_grappleHorizontalCursor];
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


- (UInt8) calculatedThreshold
{
    return 0;
//    UInt8 threshold = ([self tolerance] / 100.0) * 255.0;
//    return threshold;
}


- (void) updatePreviewGrapple
{
    Canvas *canvas = [[self owner] canvas];

    if (![[self owner] isToolSelected:self] || isnan(_lastPreviewGrapplePoint.x)) {
        [self _removePreviewGrapple];
        return;
    }
    
    BOOL isVertical = [self calculatedIsVertical];

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
    
    CGPoint point = _lastPreviewGrapplePoint;
    [self _updateLine:_previewGrapple point:point threshold:[self calculatedThreshold]];

    if (![_previewGrapple length]) {
        [self _removePreviewGrapple];
        return;
    }

    NSString *previewText = GetStringForFloat([_previewGrapple length]);
    [[CursorInfo sharedInstance] setText:previewText forKey:@"preview-grapple"];
}


#pragma mark - Private Methods

- (void) _updateLastPreviewGrapplePointWithCurrentMouseLocation
{
    CanvasView *canvasView = [[self owner] canvasView];

    CGPoint point = CGPointMake(NAN, NAN);
    if ([canvasView convertMouseLocationToCanvasPoint:&point]) {
        _lastPreviewGrapplePoint = point;
    }
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

    CGFloat xDelta = currentPoint.x - _downPoint.x;
    CGFloat yDelta = currentPoint.y - _downPoint.y;
    
    CGFloat larger = (xDelta > yDelta) ? xDelta : yDelta;
    
    NSInteger threshold  = _originalThreshold + larger;
    if (threshold < 0) threshold = 0;
    else if (threshold > 255) threshold = 255;

    NSString *cursorText = nil;

    [self _updateLine:_newGrapple point:_originalPoint threshold:threshold];

    if (threshold != _originalThreshold) {
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
    [self updatePreviewGrapple];
}


- (void) mouseMovedWithEvent:(NSEvent *)event
{
    // The grapple calculator uses floor() on the point, so pass in raw points rather
    // than rounding
    //
    _lastPreviewGrapplePoint = [self _canvasPointForEvent:event];
    [self updatePreviewGrapple];
}


- (void) mouseExitedWithEvent:(NSEvent *)event
{
    _lastPreviewGrapplePoint = NSMakePoint(NAN, NAN);
    [self updatePreviewGrapple];
}


- (BOOL) mouseDownWithEvent:(NSEvent *)event
{
    [self _removePreviewGrapple];
    
    BOOL vertical = [self calculatedIsVertical];

    _downPoint         = [event locationInWindow];
    _originalPoint     = [self _canvasPointForEvent:event];
    _originalThreshold = [self calculatedThreshold];
    
    _newGrapple = [Line lineVertical:vertical];

    [[[self owner] canvas] addCanvasObject:_newGrapple];

    CanvasObjectView *view = [[self owner] viewForCanvasObject:_newGrapple];
    [view setNewborn:YES];

    [view startTrackingWithEvent:event point:_originalPoint];

    [self _updateNewGrappleWithEvent:event];

    return YES;
}


- (void) mouseDraggedWithEvent:(NSEvent *)event
{
    [self _updateNewGrappleWithEvent:event];
}


- (void) mouseUpWithEvent:(NSEvent *)event
{
    [self _updateNewGrappleWithEvent:event];

    CanvasObjectView *view = [[self owner] viewForCanvasObject:_newGrapple];
    [view endTrackingWithEvent:event point:[self _canvasPointForEvent:event]];
    [view setNewborn:NO];

    [[CursorInfo sharedInstance] setText:nil forKey:@"new-grapple"];

    _newGrapple = nil;
}


- (void) reset
{
    [super reset];
    [self _removePreviewGrapple];
    _lastPreviewGrapplePoint = CGPointMake(NAN, NAN);
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


- (void) didUnselect
{
    [self reset];
    [self updatePreviewGrapple];
}


@end
