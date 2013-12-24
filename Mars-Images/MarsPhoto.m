//
//  MarsPhoto.m
//  Mars-Images
//
//  Created by Mark Powell on 12/22/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsPhoto.h"
#import "MarsImageNotebook.h"

@implementation MarsPhoto

- (id) initWithResource: (EDAMResource*) resource
                   note: (EDAMNote*) note
                    url: (NSURL*) url {
    self = [super initWithURL:url];
    _resource = resource;
    self.caption = [[MarsImageNotebook instance].mission captionText:resource note:note];
    return self;
}



@end
