//
//  MarsPullDownMenu.m
//  Mars-Images
//
//  Created by Mark Powell on 12/28/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsPullDownMenu.h"

@implementation MarsPullDownMenu

- (id) initWithNavigationController:(UINavigationController *)navigationController {
    self = [super initWithNavigationController:navigationController];
    
    self.cellHeight = 44;
    self.handleHeight = 15;
    self.animationDuration = 0.3f;
    self.topMarginPortrait = 0;
    self.topMarginLandscape = 0;
    self.cellColor = [UIColor lightGrayColor];
    self.cellSelectedColor = [UIColor grayColor];
    self.cellFont = [UIFont fontWithName:@"System" size:18.0f];
    self.cellTextColor = [UIColor blackColor];
    
    NSMutableArray* array = [NSMutableArray array];
    [array addObject: @"Curiosity"];
    [array addObject: @"Opportunity"];
    [array addObject: @"Spirit"];
    _menuItemNames = array;
    
    return self;
}

- (void) pullDownAnimated:(BOOL)open {
    //nothing needed here
}

- (void)menuItemSelected:(NSIndexPath *)indexPath {
    NSLog(@"menu %d selected.", indexPath.item);
}

@end
