//
//  LibraryItemView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import "LibraryItemCollectionItem.h"
#import "ThumbnailView.h"
#import "Library.h"
#import "CanvasWindowController.h"

@interface LibraryItemCollectionItem () <ThumbnailViewDelegate>
@end


@implementation LibraryItemCollectionItem  {
    ThumbnailView *_thumbnailView;
}

- (void) awakeFromNib
{
    ProtectEntry();

    NSView *selfView = [self view];
    NSRect  selfViewBounds = [selfView bounds];

    _thumbnailView = [[ThumbnailView alloc] initWithFrame:NSMakeRect(0, 20, selfViewBounds.size.width, 80)];
    [_thumbnailView setLibraryItem:[self representedObject]];
    [_thumbnailView setDelegate:self];
    [_thumbnailView loadThumbnail];
    
    [[self view] addSubview:_thumbnailView];
    
    [self _updateSelected];

    ProtectExit();
}


- (void) _updateSelected
{
    ProtectEntry();

    BOOL isSelected = [self isSelected];
    [[self textField] setTextColor:GetRGBColor(0xFFFFFF, isSelected ? 1.0 : 0.5)];
    [_thumbnailView setSelected:isSelected];

    ProtectExit();
}


- (void) thumbnailViewDidClickDelete:(ThumbnailView *)thumbnailView
{
    ProtectEntry();

    [NSApp sendAction:@selector(deleteSelectedLibraryItem:) to:nil from:self];

    ProtectExit();
}


- (void) setSelected:(BOOL)selected
{
    ProtectEntry();

    [super setSelected:selected];
    [self _updateSelected];

    ProtectExit();
}


@end
