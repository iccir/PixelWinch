//
//  LibraryItemView.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import "LibraryItemCollectionItem.h"
#import "ThumbnailView.h"


@implementation LibraryItemCollectionItem 

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self addObserver:self forKeyPath:@"selected" options:0 context:NULL];
    }
    
    return self;
}


- (void) awakeFromNib
{
    [_thumbnailView setLibraryItem:[self representedObject]];
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
    NSLog(@"delete");
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        if ([keyPath isEqualToString:@"selected"]) {
            [self _updateSelected];
        }
    }
}


@end
