//
//  ThumbnailView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import <Foundation/Foundation.h>

@class LibraryItem;


@interface ThumbnailView : NSView

+ (CGSize) thumbnailSizeForLibraryItem:(LibraryItem *)libraryItem;

@property (strong) LibraryItem *libraryItem;
@property (readonly) CGPoint topLeftOffset;
@property (assign, getter=isSelected) BOOL selected;

@end
