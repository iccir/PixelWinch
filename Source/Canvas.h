//
//  Canvas.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>

@class CanvasObject;
@class Grapple, Guide, Rectangle;
@class GrappleCalculator;
@class Screenshot;


@protocol CanvasDelegate;


@interface Canvas : NSObject

- (id) initWithDelegate:(id<CanvasDelegate>)delegate;

- (void) setupWithScreenshot: (Screenshot   *) screenshot
                  dictionary: (NSDictionary *) dictionary;

@property (nonatomic, readonly) NSUndoManager *undoManager;

@property (nonatomic, readonly) Screenshot *screenshot;
@property (nonatomic, readonly, assign) CGSize size;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@property (nonatomic, weak, readonly) id<CanvasDelegate> delegate;

- (void) addCanvasObject:(CanvasObject *)object;
- (void) removeCanvasObject:(CanvasObject *)object;


- (void) updateGrapple:(Grapple *)grapple point:(CGPoint)point threshold:(UInt8)threshold;

@property (nonatomic, readonly, strong) GrappleCalculator *grappleCalculator;
@property (nonatomic, readonly, strong) Grapple *previewGrapple;

@property (nonatomic, assign) BOOL grapplesStopOnGuides;
@property (nonatomic, assign) BOOL grapplesStopOnRectangles;


- (NSArray *) canvasObjectsWithGroupName:(NSString *)groupName;

- (void) setGroupName:(NSString *)groupName hidden:(BOOL)hidden;
- (BOOL) isGroupNameHidden:(NSString *)groupName;

@end


@protocol CanvasDelegate <NSObject>
- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object;
@end


@interface Canvas (CanvasObjectToCall)
- (void) canvasObjectWillUpdate:(CanvasObject *)object;
- (void) canvasObjectDidUpdate:(CanvasObject *)object;
@end