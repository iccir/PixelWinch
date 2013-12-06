//
//  CanvasTypes.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-12-04.
//
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, ObjectEdge) {
    ObjectEdgeNone = 0,

    ObjectEdgeTopLeft,    ObjectEdgeTop,    ObjectEdgeTopRight,
    ObjectEdgeLeft,                         ObjectEdgeRight,
    ObjectEdgeBottomLeft, ObjectEdgeBottom, ObjectEdgeBottomRight
};
