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
@class CanvasLayer;

@protocol CanvasDelegate;


@interface Canvas : NSObject

- (id) initWithDelegate:(id<CanvasDelegate>)delegate;

- (void) setupWithImage:(CGImageRef)image;
- (void) setupWithData:(NSData *)data;

@property (nonatomic, readonly, /*strong*/) CGImageRef image;
@property (nonatomic, readonly, assign) CGSize size;

@property (nonatomic, weak, readonly) id<CanvasDelegate> delegate;

- (void) removeObject:(CanvasObject *)object;

// Guides

- (Guide *) makeGuideVertical:(BOOL)vertical;
- (void) removeGuide:(Guide *)guide;

@property (nonatomic, readonly, strong) NSArray *guides;


// Grapples

- (Grapple *) makeGrappleVertical:(BOOL)vertical;
- (void) removeGrapple:(Grapple *)grapple;

@property (nonatomic, readonly, strong) NSArray *grapples;


// Rectangles

- (Rectangle *) makeRectangle;
- (void) removeRectangle:(Rectangle *)rectangle;

@property (nonatomic, readonly, strong) NSArray *rectangles;


// Marquee

- (void) clearMarquee;
- (Marquee *) makeMarquee;
@property (nonatomic, readonly, strong) Marquee *marquee;

@end


@protocol CanvasDelegate <NSObject>
- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object;
@end


@interface Canvas (CanvasObjectToCall)
- (void) objectDidUpdate:(CanvasObject *)object;
@end