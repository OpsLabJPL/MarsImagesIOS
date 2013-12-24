//
//  MarsPhoto.h
//  Mars-Images
//
//  Created by Mark Powell on 12/22/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MWPhoto.h"
#import "Evernote.h"

@interface MarsPhoto : MWPhoto

@property EDAMResource* resource;

- (id) initWithResource: (EDAMResource*) resource
                   note: (EDAMNote*) note
                    url: (NSURL*) url;

@end
