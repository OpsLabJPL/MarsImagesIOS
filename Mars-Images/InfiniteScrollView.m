//
//  InfiniteScrollView.m
//  LearnGL1
//
//  Created by Mark Powell on 10/20/13.
//  Copyright (c) 2013 Mark Powell. All rights reserved.
//

#import "InfiniteScrollView.h"

@implementation InfiniteScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self recenterIfNecessary];
}

-(void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
    if (distanceFromCenter > (contentWidth / 4.0)) {
        if ([[self recenterDelegate] respondsToSelector:@selector(willRecenterScrollView:)])
            [[self recenterDelegate] willRecenterScrollView:self];
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        if ([[self recenterDelegate] respondsToSelector:@selector(didRecenterScrollView:)])
            [[self recenterDelegate] didRecenterScrollView:self];
    }
}
@end
