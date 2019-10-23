//  (c) 2013-2018, Ricci Adams.  All rights reserved.


@interface BaseView : NSView

- (id) initWithFrame:(CGRect)frame;

- (void) layoutSubviews;

@property (nonatomic, copy) NSColor *backgroundColor;

@end

