//
//  LibraryItemView.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import <Foundation/Foundation.h>
@class ThumbnailView;

@interface LibraryItemCollectionItem : NSCollectionViewItem

- (IBAction) deleteItem:(id)sender;

@property (nonatomic, weak) IBOutlet ThumbnailView *thumbnailView;
@property (nonatomic, weak) IBOutlet NSButton *deleteButton;

@end
