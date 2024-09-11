// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@class RulerView;

@interface CenteringClipView : NSClipView

@property (nonatomic, weak) RulerView *horizontalRulerView;
@property (nonatomic, weak) RulerView *verticalRulerView;

@end
