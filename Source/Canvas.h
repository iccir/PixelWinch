//
//  Canvas.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-02.
//
//

#import <Foundation/Foundation.h>

@class CanvasObject;
@class Screenshot;



@protocol CanvasDelegate;


@interface Canvas : NSObject

- (id) initWithDelegate:(id<CanvasDelegate>)delegate;

- (void) setupWithScreenshot: (Screenshot   *) screenshot
                  dictionary: (NSDictionary *) dictionary;

@property (nonatomic, readonly) NSUndoManager *undoManager;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@property (nonatomic, weak, readonly) id<CanvasDelegate> delegate;

@property (nonatomic, readonly) Screenshot *screenshot;

@property (nonatomic, readonly, assign) CGSize size;

- (void) addCanvasObject:(CanvasObject *)object;
- (void) removeCanvasObject:(CanvasObject *)object;

- (void) unselectAllObjects;
- (void) unselectObject:(CanvasObject *)object;
- (void) selectObject:(CanvasObject *)object;
@property (nonatomic, copy, readonly) NSArray *selectedObjects;

- (NSArray *) allCanvasObjects;
- (NSArray *) canvasObjectsWithGroupName:(NSString *)groupName;

- (void) setGroupName:(NSString *)groupName hidden:(BOOL)hidden;
- (BOOL) isGroupNameHidden:(NSString *)groupName;

- (void) dumpDistanceMaps;

- (size_t) distancePlaneWidth;
- (size_t) distancePlaneHeight;
- (UInt8 *) horizontalDistancePlane NS_RETURNS_INNER_POINTER;
- (UInt8 *) verticalDistancePlane   NS_RETURNS_INNER_POINTER;

@end


@protocol CanvasDelegate <NSObject>
- (void) canvasDidChangeHiddenGroupNames:(Canvas *)canvas;
- (void) canvas:(Canvas *)canvas didAddObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didUpdateObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didRemoveObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didSelectObject:(CanvasObject *)object;
- (void) canvas:(Canvas *)canvas didUnselectObject:(CanvasObject *)object;
@end


@interface Canvas (CanvasObjectToCall)
- (void) canvasObjectWillUpdate:(CanvasObject *)object;
- (void) canvasObjectDidUpdate:(CanvasObject *)object;
@end

