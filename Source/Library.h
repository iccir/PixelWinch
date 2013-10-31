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

- (void) addItem:(LibraryItem *)item;
- (void) removeItem:(LibraryItem *)item;
- (void) discardItem:(LibraryItem *)item;

@property (nonatomic, readonly) NSArray *items;

@end

