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

- (LibraryItem *) makeItem;
- (void) removeItem:(LibraryItem *)item;

@property (readonly) NSArray *items;

@end

