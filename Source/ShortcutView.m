//
//  ShortcutField.m
//  PixelWinch
//
//  Created by Ricci Adams on 4/22/11.
//  Copyright 2011 Ricci Adams. All rights reserved.
//

#import "ShortcutView.h"

#import "ShortcutManager.h"
#import "Shortcut.h"


@interface ShortcutView ()
@end


@interface _ShortcutCell : NSActionCell

- (NSRect) rectOfClearIconForFrame:(NSRect)frame;

@property (nonatomic, strong) Shortcut *shortcut;
@property (nonatomic, assign, getter=isMouseDownInClearIcon) BOOL mouseDownInClearIcon;

@end


static NSGradient *sMakeGradient(CGFloat gray1, CGFloat gray2, CGFloat location1, CGFloat location2)
{
    NSColor *color1 = [NSColor colorWithDeviceWhite:gray1 alpha:1.0];
    NSColor *color2 = [NSColor colorWithDeviceWhite:gray2 alpha:1.0];

    return [[NSGradient alloc] initWithColorsAndLocations:color1, location1, color2, location2, nil];
}


static NSBezierPath *sMakeRoundedPath(CGRect rect)
{
    CGFloat halfWidth  = rect.size.width / 2.0;
    CGFloat halfHeight = rect.size.height / 2.0;
    CGFloat radius     = MIN(halfWidth, halfHeight);
        
    return [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
}


static NSImage *sMakeClearIcon(BOOL isPressed)
{
    NSGradient *gradient = nil;

    if (isPressed) {
        gradient = sMakeGradient(0.66, 0.5, 0.0, 1.0);
    } else {
        gradient = sMakeGradient(0.75, 0.66, 0.0, 1.0);
    }

    NSImage *result = [[NSImage alloc] initWithSize:NSMakeSize(14.0, 14.0)];

    [result lockFocus];
    
    NSImage    *template = [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
    NSSize      size     = [template size];

    NSRect toRect = NSMakeRect(0.0, 0.0, 14.0, 14.0);
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:toRect] angle:-90];
    [template drawInRect:toRect fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositeDestinationIn fraction:1.0];

    [result unlockFocus];
    
    return result;
}


static NSImage *sGetPressedClearIcon()
{
    static NSImage *result = nil;
    if (!result) result = sMakeClearIcon(YES);
    return result;
}


static NSImage *sGetClearIcon()
{
    static NSImage *result = nil;
    if (!result) result = sMakeClearIcon(NO);
    return result;
}


@implementation ShortcutView

+ (void) initialize
{
    if (self == [ShortcutView class]) {
        [self setCellClass:[_ShortcutCell class]];
    }
}


+ (Class) cellClass
{
    return [_ShortcutCell class];
}


#pragma mark -
#pragma mark Private Methods

- (_ShortcutCell *) _shortcutCell
{
    NSCell *cell = [self cell];
    
    if ([cell isKindOfClass:[_ShortcutCell class]]) {
        return (_ShortcutCell *)cell;
    }
    
    return nil;
}


- (BOOL) _isEventForClearIcon:(NSEvent *)event
{
    NSPoint location = [event locationInWindow];
    location = [self convertPoint:location fromView:nil];

    NSRect rectOfClearIcon = [[self _shortcutCell] rectOfClearIconForFrame:[self bounds]];
    return ([self shortcut] && NSPointInRect(location, rectOfClearIcon));
}


#pragma mark -
#pragma mark Superclass Overrides

- (BOOL) needsPanelToBecomeKey
{
    return YES;
}


- (BOOL) acceptsFirstResponder
{
    return YES;
}


- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}


- (BOOL) becomeFirstResponder 
{
    NSEvent     *event     = [NSApp currentEvent];
    NSEventType  eventType = [event type];

    if ((eventType == NSLeftMouseDown) || (eventType == NSRightMouseDown)) {
        if ([self _isEventForClearIcon:event]) {
            return NO;
        }
    }

    [self setNeedsDisplay:YES];
    [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return YES;
}


- (BOOL) resignFirstResponder 
{
    [super resignFirstResponder];

    [self setNeedsDisplay:YES];
    [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return YES;
}


- (void) mouseDown:(NSEvent *)theEvent
{
    if ([self _isEventForClearIcon:theEvent]) {
        [[self cell] setMouseDownInClearIcon:YES];
        [self setNeedsDisplay:YES];
        
    } else {
        [super mouseDown:theEvent];
    }
}


- (void) mouseUp:(NSEvent *)theEvent
{
    if ([[self cell] isMouseDownInClearIcon]) {
        [[self cell] setMouseDownInClearIcon:NO];
        [self setNeedsDisplay:YES];

        if ([self shortcut]) {
            [self setShortcut:nil];
            [self sendAction:[self action] to:[self target]];
            
            if ([[self window] firstResponder] == self) {
                [[self window] makeFirstResponder:nil];
            }
            
            return;
        }
    }

    [super mouseUp:theEvent];
}


- (BOOL) performKeyEquivalent:(NSEvent *)theEvent
{
    if ([[self window] firstResponder] != self) {
        return NO;
    }

    NSEventModifierFlags modifierFlags = [theEvent modifierFlags] & (
        NSEventModifierFlagControl  |
        NSEventModifierFlagShift    |
        NSEventModifierFlagOption   |
        NSEventModifierFlagCommand  |
        NSEventModifierFlagFunction
    );

    NSString  *characters = [theEvent characters];
    unichar    c          = [characters length] ? [characters characterAtIndex:0] : 0;

    if (modifierFlags == 0) { 
        if (c == 0x1b /* Escape */) {
            [[self window] makeFirstResponder:nil];

        } else if (c == NSDeleteCharacter || c == NSBackspaceCharacter) {
            [self setShortcut:nil];
            [self sendAction:[self action] to:[self target]];

        } else {
            return [super performKeyEquivalent:theEvent];
        }
        
    } else if ((modifierFlags == NSEventModifierFlagShift) && (c == NSBackTabCharacter || c == NSTabCharacter)) {
        return [super performKeyEquivalent:theEvent];
        
	} else {
        Shortcut *shortcut = [Shortcut shortcutWithWithKeyCode:[theEvent keyCode] modifierFlags:modifierFlags];
        [self setShortcut:shortcut];
        [self sendAction:[self action] to:[self target]];
    }

    return YES;
}


#pragma mark -
#pragma mark Accessors

- (void) setShortcut:(Shortcut *)shortcut
{
    [[self _shortcutCell] setShortcut:shortcut];
    [self setNeedsDisplay:YES];
}


- (Shortcut *) shortcut
{
    return [[self _shortcutCell] shortcut];
}


@end


@implementation _ShortcutCell


- (BOOL) acceptsFirstResponder
{
    return YES;
}


- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}


- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CGFloat maxX = NSMaxX(cellFrame);

    NSBezierPath *boundsPath = sMakeRoundedPath(cellFrame);
    
    // Draw background
    //
    {
        [[NSColor whiteColor] set];
        [boundsPath fill];
    }


    // Draw circle X
    //
    if (_shortcut) {
        CGRect clearImageRect = [self rectOfClearIconForFrame:cellFrame];
        maxX = NSMaxX(clearImageRect);
        
        NSImage *image = sGetClearIcon();
        if (_mouseDownInClearIcon) {
            image = sGetPressedClearIcon();
        }

        [image drawInRect:clearImageRect];
    }

    
    // Draw text string
    //
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        NSString *stringToDraw = nil;
        NSRect stringRect = cellFrame;
        NSColor *color = [NSColor blackColor];
        CGFloat fontSize = 13.0;

        stringRect.size.width = maxX - cellFrame.origin.x;

        [style setAlignment:NSTextAlignmentCenter];

        if (_shortcut) {
            stringToDraw = [_shortcut displayString];
            stringRect = NSInsetRect(stringRect, 3, 2);

        } else {
            if ([self showsFirstResponder]) {
                stringToDraw = NSLocalizedString(@"Type shortcut", @"");
            } else {
                stringToDraw = NSLocalizedString(@"Click to record shortcut", @"");
            }

            fontSize = 11.0;
            color = [NSColor colorWithDeviceWhite:0.5 alpha:1.0];
            stringRect = NSInsetRect(stringRect, 3, 4);
        }

        NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSFont systemFontOfSize:fontSize], NSFontAttributeName,
            style, NSParagraphStyleAttributeName,
            color, NSForegroundColorAttributeName,
            nil];

        [stringToDraw drawInRect:stringRect withAttributes:attributes];
    }


    // Draw focus ring if necessary
    //
    if ([self showsFirstResponder]) {
        [NSGraphicsContext saveGraphicsState];

        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSColor whiteColor] set];
        [boundsPath fill];

        [NSGraphicsContext restoreGraphicsState];
    }


    // Apply stroke
    {
        NSBezierPath *path = sMakeRoundedPath(NSInsetRect(cellFrame, 0.5, 0.5));
        
        if ([self showsFirstResponder]) {
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.15] set];
        } else {
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.33] set];
        }

        [path stroke];
    }
}


- (NSRect) rectOfClearIconForFrame:(NSRect)frame
{
    NSImage *image     = sGetClearIcon();
    NSSize   imageSize = [image size];
    CGFloat  x         = NSMaxX(frame) - 18.0;

    NSPoint point = NSMakePoint(x, frame.origin.y);
    point.y += round((frame.size.height - 14.0) / 2.0);
 
    NSRect result = { point, imageSize };
    
    return result;
}


@end
