//
//  Library.h
//  PixelWinch
//
//  Created by Ricci Adams on 2013-10-08.
//
//

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

