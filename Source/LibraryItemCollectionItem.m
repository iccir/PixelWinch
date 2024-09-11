// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

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
    NSView *selfView = [self view];
    NSRect  selfViewBounds = [selfView bounds];

    _thumbnailView = [[ThumbnailView alloc] initWithFrame:NSMakeRect(0, 20, selfViewBounds.size.width, 80)];
    [_thumbnailView setLibraryItem:[self representedObject]];
    [_thumbnailView setDelegate:self];
    [_thumbnailView loadThumbnail];
    
    [[self view] addSubview:_thumbnailView];
    
    [self _updateSelected];
}


- (void) _updateSelected
{
    BOOL isSelected = [self isSelected];
    
    NSString *colorName = isSelected ? @"LibraryTextSelected" : @"LibraryText";
    [[self textField] setTextColor:[NSColor colorNamed:colorName]];
    
    [_thumbnailView setSelected:isSelected];
}


- (void) thumbnailViewDidClickDelete:(ThumbnailView *)thumbnailView
{
    [NSApp sendAction:@selector(deleteSelectedLibraryItem:) to:nil from:self];
}


- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self _updateSelected];
}


@end
