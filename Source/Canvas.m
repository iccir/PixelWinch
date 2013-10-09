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

static NSString * const sGuidesKey     = @"guides";
static NSString * const sGrapplesKey   = @"grapples";
static NSString * const sRectanglesKey = @"rectangles";



@implementation Canvas {
    NSMutableArray *_guides;
    NSMutableArray *_grapples;
    NSMutableArray *_rectangles;
}


- (id) initWithDelegate:(id<CanvasDelegate>)delegate
{
    if ((self = [super init])) {
        _delegate   = delegate;
        _guides     = [NSMutableArray array];
        _rectangles = [NSMutableArray array];
        _grapples   = [NSMutableArray array];
    }
    
    return self;
}


- (id) init
{
    return [self initWithDelegate:nil];
}


- (void) setupWithImage:(CGImageRef)image
{
    if (_image) return;
    _image = CGImageRetain(image);

    if (image) {
        _size = CGSizeMake(CGImageGetWidth(_image), CGImageGetHeight(_image));
    }
}


- (void) setupWithData:(NSData *)data
{
    NSDictionary *dictionary;

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
}


- (void) dealloc
{
    CGImageRelease(_image);
}


- (void) objectDidUpdate:(CanvasObject *)object
{
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



#pragma mark - Guides

- (void) removeObject:(CanvasObject *)object
{
    if ([object isKindOfClass:[Guide class]]) {
        [self removeGuide:(Guide *)object];

    } else if ([object isKindOfClass:[Grapple class]]) {
        [self removeGrapple:(Grapple *)object];

    } else if ([object isKindOfClass:[Rectangle class]]) {
        [self removeRectangle:(Rectangle *)object];
    }
}


- (Guide *) makeGuideVertical:(BOOL)vertical
{
    Guide *guide = [Guide guideWithOffset:-1 vertical:vertical];
    [guide setCanvas:self];
    [_guides addObject:guide];

    [self _didAddObject:guide];

    return guide;
}


- (void) removeGuide:(Guide *)guide
{
    if (!guide) return;
    [_guides removeObject:guide];
    [self _didRemoveObject:guide];
}


- (Grapple *) makeGrappleVertical:(BOOL)vertical
{
    Grapple *grapple = [Grapple grappleVertical:vertical];
    [grapple setCanvas:self];
    [_grapples addObject:grapple];

    [self _didAddObject:grapple];

    return grapple;
}


- (void) removeGrapple:(Grapple *)grapple
{
    if (!grapple) return;
    [_grapples removeObject:grapple];
    [self _didRemoveObject:grapple];
}


- (Rectangle *) makeRectangle
{
    Rectangle *rectangle = [Rectangle rectangle];
    [rectangle setCanvas:self];
    [_rectangles addObject:rectangle];

    [self _didAddObject:rectangle];

    return rectangle;
}


- (void) removeRectangle:(Rectangle *)rectangle
{
    if (!rectangle) return;
    [_rectangles removeObject:rectangle];
    [self _didRemoveObject:rectangle];
}


- (void) clearMarquee
{
    Marquee *marquee = _marquee;

    if (marquee) {
        _marquee = nil;
        [self _didRemoveObject:marquee];
    }
}


- (Marquee *) makeMarquee
{
    [self clearMarquee];
    _marquee = [[Marquee alloc] init];
    [_marquee setCanvas:self];
    [self _didAddObject:_marquee];
    
    return _marquee;
}



@end
