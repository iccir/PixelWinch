//  (c) 2013-2018, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@class LibraryItem;

@protocol ThumbnailViewDelegate;

@interface ThumbnailView : NSView

- (void) loadThumbnail;

@property (strong) LibraryItem *libraryItem;
@property (assign, getter=isSelected) BOOL selected;

@property (atomic, weak) id<ThumbnailViewDelegate> delegate;

@end

@protocol ThumbnailViewDelegate <NSObject>
- (void) thumbnailViewDidClickDelete:(ThumbnailView *)thumbnailView;
@end
