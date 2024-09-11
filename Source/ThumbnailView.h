// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
