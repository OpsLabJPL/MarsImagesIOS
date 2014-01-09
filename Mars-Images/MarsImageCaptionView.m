//
//  MarsImageCaptionView.m
//  Mars-Images
//
//  Created by Mark Powell on 1/8/14.
//  Copyright (c) 2014 Powellware. All rights reserved.
//

#import "MarsImageCaptionView.h"

@implementation MarsImageCaptionView

- (id)initWithPhoto:(id<MWPhoto>)photo {
    self = [super initWithPhoto:photo];
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (size.width > 100) {
        return [super sizeThatFits:size];
    }
    return CGSizeMake(0,0);
}

@end
