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

@property (strong) LibraryItem *libraryItem;
@property (assign, getter=isSelected) BOOL selected;

@end
