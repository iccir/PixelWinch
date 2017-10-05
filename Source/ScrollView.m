//  (c) 2013-2017, Ricci Adams.  All rights reserved.


#import "ScrollView.h"

@implementation ScrollView {
    BlackSquare *_bottomRight;
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) tile
{
    [super tile];

    if (!_bottomRight) {
        _bottomRight = [[BlackSquare alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];
    }

    if ([[self subviews] lastObject] != _bottomRight) {
        [self addSubview:_bottomRight];
    }

    NSRect bounds = [self bounds];
    [_bottomRight setFrame:NSMakeRect(bounds.size.width - 15, bounds.size.height - 15, 15, 15)];
}


@end
