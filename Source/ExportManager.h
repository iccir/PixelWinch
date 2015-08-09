//
//  ExportManager.h
//  Pixel Winch
//
//  Created by Ricci Adams on 2015-08-08.
//
//

#import <Foundation/Foundation.h>

@class Canvas;


@interface ExportManager : NSObject

- (void) exportCanvas:(Canvas *)canvas toFileURL:(NSURL *)fileURL;

@end
