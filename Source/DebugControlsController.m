//
//  DebugControlsViewController.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2013-10-24.
//
//

#import "DebugControlsController.h"

#ifdef DEBUG


@interface DebugControlsController ()

@end

@implementation DebugControlsController


- (NSString *) windowNibName
{
    return @"Controls";
}

- (void) awakeFromNib
{
    [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
}


@end

#endif