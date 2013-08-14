//
//  Search.h
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Search : NSObject

@property (nonatomic, strong) NSMutableArray* searches;

- (NSArray*) filterSearchText:(NSString*)searchTerm;
- (void) initSearchTerms;
- (void) updateSearchTerms:(NSString*)userSearch;

+ (Search*) instance;

@end
