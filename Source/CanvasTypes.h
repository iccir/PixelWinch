// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, ObjectEdge) {
    ObjectEdgeNone = 0,

    ObjectEdgeTopLeft,    ObjectEdgeTop,    ObjectEdgeTopRight,
    ObjectEdgeLeft,                         ObjectEdgeRight,
    ObjectEdgeBottomLeft, ObjectEdgeBottom, ObjectEdgeBottomRight
};
