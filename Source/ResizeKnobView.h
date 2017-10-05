//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>
#import "CanvasObjectView.h"

@interface ResizeKnobView : CanvasObjectView

@property (nonatomic, weak) CanvasObjectView *owningObjectView;
@property (nonatomic) ObjectEdge edge;

@property (nonatomic) BOOL highlighted;

- (void) hideMomentarily;

@end
