//
//  Grapple.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-01.
//
//

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Grapple : CanvasObject

+ (instancetype) grappleVertical:(BOOL)vertical;

- (CGFloat) length;

- (void) setRect:(CGRect)rect stickyStart:(BOOL)stickyStart stickyEnd:(BOOL)stickyEnd;

@property (nonatomic, readonly, getter=isVertical) BOOL vertical;
@property (nonatomic, assign, getter=isPreview) BOOL preview;

@property (nonatomic, readonly, assign) BOOL stickyStart;
@property (nonatomic, readonly, assign) BOOL stickyEnd;

@property (nonatomic, assign) CGFloat startOffset;
@property (nonatomic, assign) CGFloat endOffset;

@end
