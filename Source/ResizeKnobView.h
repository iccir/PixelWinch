// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@interface ResizeKnobView : CanvasObjectView

@property (nonatomic, weak) CanvasObjectView *owningObjectView;
@property (nonatomic) ObjectEdge edge;

@property (nonatomic) BOOL highlighted;

- (void) hideMomentarily;

@end
