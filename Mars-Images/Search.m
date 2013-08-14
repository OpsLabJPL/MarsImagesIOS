//
//  Search.m
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "Search.h"

@implementation Search

@synthesize searches;

+ (Search*) instance {
    static Search* instance = nil;
    if (!instance) {
        instance = [[Search alloc] init];
        [instance initSearchTerms];
    }
    return instance;
}

//TODO make this mission specific
- (void) initSearchTerms {
    self.searches = [[NSMutableArray alloc] initWithObjects: @"Navcam", @"Front Hazcam", @"Rear Hazcam", @"Pancam", nil];
}

- (NSArray*) filterSearchText:(NSString *)searchTerm {
    if (searchTerm && [searchTerm length] > 0) {
        NSMutableArray* filteredSearches = [[NSMutableArray alloc] init];
        for (int i = 0; i < [searches count]; i++) {
            NSString* searchable = [searches objectAtIndex:i];
            if ([searchable rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound)
                [filteredSearches addObject:searchable];
        }
        return filteredSearches;
    } else {
        return searches;
    }
}

-(void)updateSearchTerms:(NSString *)userSearch {
    for (int i = 0; i < [searches count]; i++) {
        if ([[searches objectAtIndex:i] isEqualToString:userSearch]) {
            return;
        }
    }
    [searches addObject: userSearch];
}

@end
