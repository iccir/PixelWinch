//
//  CenteringClipView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-04.
//
//

#import <Foundation/Foundation.h>

@class RulerView;

@interface CenteringClipView : NSClipView

@property (nonatomic, weak) RulerView *horizontalRulerView;
@property (nonatomic, weak) RulerView *verticalRulerView;

@end
