// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>
#import "CanvasObject.h"

@interface Marquee : CanvasObject
- (BOOL) writeToPasteboard:(NSPasteboard *)pasteboard;
@end
