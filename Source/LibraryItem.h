//
//  LibraryItem.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-15.
//
//

#import <Foundation/Foundation.h>

@class Screenshot;

@interface LibraryItem : NSObject

@property (nonatomic, readonly) NSString *screenshotPath;
@property (nonatomic, readonly) Screenshot *screenshot;

@property (nonatomic, readonly) NSImage *thumbnail;

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDictionary *canvasDictionary;

@property (nonatomic, readonly) NSString *titleOrDateString;

@property (nonatomic, copy) NSString *dateString;

@property (nonatomic, readonly, getter=isValid) BOOL valid;

@end
