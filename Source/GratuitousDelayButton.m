//
//  GratuitousDelayButton.m
//  Pixel Winch
//
//  Created by Ricci Adams on 2015-01-16.
//
//

#import "GratuitousDelayButton.h"

@interface GratuitousDelayPieceView : XUIView
@property (atomic, strong) NSColor  *color;
@property (atomic) BOOL drawsShadow;
@end

@implementation GratuitousDelayButton {
    NSTrackingArea           *_trackingArea;
    GratuitousDelayPieceView *_whitePiece;
    GratuitousDelayPieceView *_grayPiece;
    CALayer                  *_maskLayer;
}

- (id) initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        [self _setup];
    }
    
    return self;
}


- (void) dealloc
{
    [self removeTrackingArea:_trackingArea];
    _trackingArea = nil;
}


static void sRectCenter(CGRect *target, const CGRect other)
{
    const CGSize targetSize = target->size;

    target->origin.x = other.origin.x + round((other.size.width  - targetSize.width)  / 2.0);
    target->origin.y = other.origin.y + round((other.size.height - targetSize.height) / 2.0);
}


- (void) _setup
{
    NSTrackingAreaOptions options = NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow|NSTrackingCursorUpdate;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:options owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];

    CGRect bounds = [self bounds];
    
    NSImage *image = [NSImage imageNamed:@"GratuitousDelay"];
    CGSize imageSize = [image size];


    CGRect whitePieceFrame = { CGPointZero, imageSize };
    CGRect grayPieceFrame  = CGRectInset(whitePieceFrame, -16, -16);

    sRectCenter(&whitePieceFrame, bounds);
    sRectCenter(&grayPieceFrame,  bounds);
    
    _whitePiece = [[GratuitousDelayPieceView alloc] initWithFrame:whitePieceFrame];
    _grayPiece  = [[GratuitousDelayPieceView alloc] initWithFrame:grayPieceFrame];

    [_whitePiece setColor:[NSColor whiteColor]];
    [_grayPiece setColor:GetRGBColor(0xa0a0a0, 1.0)];
    [_grayPiece setDrawsShadow:YES];

    _maskLayer = [CALayer layer];
    [_maskLayer setBackgroundColor:[[NSColor blackColor] CGColor]];
    [_maskLayer setFrame:[_whitePiece bounds]];
    [[_whitePiece layer] setMask:_maskLayer];

    [self addSubview:_grayPiece];
    [self addSubview:_whitePiece];

    [_maskLayer setTransform:CATransform3DMakeTranslation(-imageSize.width, 0, 0)];
}


- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}


- (void) mouseUp:(NSEvent *)theEvent
{
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    [appDelegate showPurchasePane:self];
}


- (void) cursorUpdate:(NSEvent *)event
{
    [[NSCursor pointingHandCursor] set];
}


- (CALayer *) maskLayer
{
    return _maskLayer;
}


@end


@implementation GratuitousDelayPieceView

- (void) drawRect:(NSRect)dirtyRect
{
    CGContextRef context = XUIGraphicsGetCurrentContext();

    CGRect bounds = [self bounds];

    NSImage *image     = [NSImage imageNamed:@"GratuitousDelay"];
    CGSize   imageSize = [image size];

    NSRect imageRect = { CGPointZero, imageSize };
    sRectCenter(&imageRect, bounds);
    
    if (_drawsShadow) {
        CGContextSetShadowWithColor(context, CGSizeMake(0, -2), 8, [[NSColor blackColor] CGColor]);
        CGContextBeginTransparencyLayer(context, NULL);
    }

    [image drawInRect:imageRect];
    [_color set];
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextFillRect(context, imageRect);

    if (_drawsShadow) {
        CGContextEndTransparencyLayer(context);
    }
}



@end
