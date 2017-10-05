//  (c) 2015-2017, Ricci Adams.  All rights reserved.


#import <Foundation/Foundation.h>

@class Canvas;


@interface ExportManager : NSObject

- (void) exportCanvas:(Canvas *)canvas toFileURL:(NSURL *)fileURL;

@end
