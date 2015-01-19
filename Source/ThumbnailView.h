//
//  ThumbnailView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

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
