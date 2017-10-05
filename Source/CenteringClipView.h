//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@class RulerView;

@interface CenteringClipView : NSClipView

@property (nonatomic, weak) RulerView *horizontalRulerView;
@property (nonatomic, weak) RulerView *verticalRulerView;

@end
