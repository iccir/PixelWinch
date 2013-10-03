//
//  ToolPaletteController.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-28.
//
//

#import "ToolController.h"

@interface ToolController ()

@end

@implementation ToolController

- (NSString *) nibName
{
    return @"ToolPalette";
}

- (void) awakeFromNib
{
    [_moveButton     setTag:ToolTypeMove];
    [_marqueeButton  setTag:ToolTypeMarquee];
    [_boxLaserButton setTag:ToolTypeRectangle];
    [_zoomButton     setTag:ToolTypeZoom];
}


- (IBAction) selectTool:(id)sender
{
    ToolType selectedTool = [sender tag];

    void (^t)(NSButton *) = ^(NSButton *button) {
        if ([button tag] == selectedTool) {
            [button setState:NSOnState];
        } else {
            [button setState:NSOffState];
        }
    };

    t( _moveButton     );
    t( _marqueeButton  );
    t( _boxLaserButton );
    t( _zoomButton     );
    
    [self setSelectedTool:selectedTool];
}

@end
