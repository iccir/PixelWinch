// (c) 2013-2024 Ricci Adams
// MIT License (or) 1-clause BSD License

#import <Foundation/Foundation.h>

@class LibraryItem;

@interface Library : NSObject

+ (instancetype) sharedInstance;

- (LibraryItem *) importedItemAtPath:(NSString *)filePath;
- (LibraryItem *) importedItemWithData:(NSData *)data;

- (void) addItem:(LibraryItem *)item;
- (void) removeItem:(LibraryItem *)item;
- (void) discardItem:(LibraryItem *)item;

@property (nonatomic, readonly) NSArray<LibraryItem *> *items;

@end

