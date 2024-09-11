// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@class Screenshot;

@interface LibraryItem : NSObject

+ (instancetype) libraryItem;

@property (atomic, readonly) NSString *screenshotPath;
@property (atomic, readonly) NSString *thumbnailPath;

@property (atomic, readonly) NSDate *date;

@property (atomic, readonly, getter=isValid) BOOL valid;

@property (atomic, readonly) Screenshot   *screenshot;
@property (atomic, strong)   NSDictionary *canvasDictionary;
@property (atomic, copy)     NSString *title;
@property (atomic, copy)     NSString *dateString;
@property (atomic, readonly) NSString *titleOrDateString;

// Not persisted
@property (atomic) CGFloat magnification;
@property (atomic) CGPoint scrollOrigin;

@end
