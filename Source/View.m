//
//  View.m
//  PixelWinch
//
//  Created by Ricci Adams on 2013-09-29.
//
//

#import "View.h"

@implementation View

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (BOOL) isFlipped
{
    return YES;
}

@end
