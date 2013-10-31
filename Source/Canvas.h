//
//  Canvas.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>

@class CanvasObject;
@class Grapple, Guide, Marquee, Rectangle;
@class GrappleCalculator;
@class Screenshot;


@protocol CanvasDelegate;


@interface Canvas : NSObject

- (id) initWithDelegate:(id<CanvasDelegate>)delegate;

- (void) setupWithScreenshot: (Screenshot   *) screenshot
                  dictionary: (NSDictionary *) dictionary;

@property (readonly) NSUndoManager *undoManager;

@property (nonatomic, readonly) Screenshot *screenshot;
@property (nonatomic, readonly, assign) CGSize size;

@property (readonly) NSDictionary *dictionaryRepresentation;

@property (nonatomic, weak, readonly) id<CanvasDelegate> delegate;

- (void) removeObject:(CanvasObject *)object;

// Guides

- (Guide *) makeGuideVertical:(BOOL)vertical;
- (void) removeGuide:(Guide *)guide;

@property (nonatomic, readonly, strong) NSArray *guides;
@property (nonatomic, assign, getter=areGuidesHidden) BOOL guidesHidden;


// Grapples

- (Grapple *) makeGrappleVertical:(BOOL)vertical;
- (void) removeGrapple:(Grapple *)grapple;

- (Grapple *) makePreviewGrappleVertical:(BOOL)vertical;
- (void) removePreviewGrapple;

- (void) updateGrapple:(Grapple *)grapple point:(CGPoint)point threshold:(UInt8)threshold;

@property (nonatomic, readonly, strong) GrappleCalculator *grappleCalculator;
@property (nonatomic, readonly, strong) Grapple *previewGrapple;
@property (nonatomic, readonly, strong) NSArray *grapples;

@property (nonatomic, assign) BOOL grapplesStopOnGuides;
@property (nonatomic, assign) BOOL grapplesStopOnRectangles;

// Rectangles

- (Rectangle *) makeRectangle;
- (void) removeRectangle:(Rectangle *)rectangle;

@property (nonatomic, readonly, strong) NSArray *rectangles;


// Marquee

- (Marquee *) makeMarquee;
@property (nonatomic, readonly, strong) Marquee *marquee;
@property (nonatomic, assign, getter=isMarqueeHidden) BOOL marqueeHidden;

@end


@protocol CanvasDelegate <NSObject>
- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object;
@end


@interface Canvas (CanvasObjectToCall)
- (void) objectWillUpdate:(CanvasObject *)object;
- (void) objectDidUpdate:(CanvasObject *)object;
@end