//
//  FixedImageTableViewCell.m
//  Mars-Images
//
//  Created by Mark Powell on 11/18/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "FixedWidthImageTableViewCell.h"

@implementation FixedWidthImageTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    int height = self.bounds.size.height;
    self.imageView.frame = CGRectMake(0,0,height,height);
    self.textLabel.frame = CGRectMake(50,2,500,20);
    self.detailTextLabel.frame = CGRectMake(50,24,500,20);
}

@end
