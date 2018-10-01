//  (c) 2013-2018, Ricci Adams.  All rights reserved.


@interface BaseView : NSView

- (id) initWithFrame:(CGRect)frame;

- (void) layoutSubviews;

@property (atomic, readwrite) NSInteger tag;

@property (nonatomic) BOOL clipsToBounds;
@property (nonatomic, copy) NSColor *backgroundColor;

// Defaults to YES
@property (atomic, readwrite, getter=isFlipped) BOOL flipped;

@end

