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
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];
        [self setContentSize:CGSizeMake(10000, 10000)];
        [self setContentOffset:CGPointMake(5000,5000)];
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
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
    CGFloat distanceFromCenter = (fabs(currentOffset.x - centerOffsetX) + fabs(currentOffset.y - centerOffsetY));
    if (distanceFromCenter > (contentWidth / 4.0)) {
        if ([[self recenterDelegate] respondsToSelector:@selector(willRecenterScrollView:)])
            [[self recenterDelegate] willRecenterScrollView:self];
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        if ([[self recenterDelegate] respondsToSelector:@selector(didRecenterScrollView:)])
            [[self recenterDelegate] didRecenterScrollView:self];
    }
}
@end
