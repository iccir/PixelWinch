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
#import "CanvasController.h"


@implementation LibraryItemCollectionItem 

- (void) awakeFromNib
{
    [_thumbnailView setLibraryItem:[self representedObject]];
    
    CGPoint topLeftOffset = [_thumbnailView topLeftOffset];
    CGRect bounds = [[self view] bounds];
    
    CGRect deleteFrame = [[self deleteButton] frame];
    
    CGFloat maxY = bounds.size.height - deleteFrame.size.height;
    
    CGPoint origin = CGPointMake(topLeftOffset.x, bounds.size.height - (topLeftOffset.y + deleteFrame.size.height));
    deleteFrame.origin = origin;
    deleteFrame.origin.x -= 14;
    deleteFrame.origin.y += 13;
    
    if (deleteFrame.origin.x < 0)    deleteFrame.origin.x = 0;
    if (deleteFrame.origin.y > maxY) deleteFrame.origin.y = maxY;

    [[self deleteButton] setFrame:deleteFrame];
    
    [self _updateSelected];
}


- (void) _updateSelected
{
    BOOL isSelected = [self isSelected];
    [[self textField] setTextColor:GetRGBColor(0xFFFFFF, isSelected ? 1.0 : 0.5)];
    [[self thumbnailView] setSelected:isSelected];
    [[self deleteButton] setHidden:!isSelected];
}


- (IBAction) deleteItem:(id)sender
{
    [NSApp sendAction:@selector(deleteSelectedLibraryItem:) to:nil from:self];
}


- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self _updateSelected];
}


@end
