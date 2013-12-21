//
//  MarsImageCaptionView.m
//  Mars-Images
//
//  Created by Mark Powell on 10/26/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsImageCaptionView.h"

@implementation MarsImageCaptionView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void) setupCaption {
    [super setupCaption];
//    UILabel* stupidLabel = [[UILabel alloc] initWithFrame:CGRectIntegral(CGRectMake(5,5,150,20))];
//    stupidLabel.text = @"Hello, world!";
//    stupidLabel.font = [UIFont systemFontOfSize:10];
//    [self addSubview:stupidLabel];
}
@end
