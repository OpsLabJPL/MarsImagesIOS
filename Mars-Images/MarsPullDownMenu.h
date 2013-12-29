//
//  MarsPullDownMenu.h
//  Mars-Images
//
//  Created by Mark Powell on 12/28/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "PulldownMenu.h"

@interface MarsPullDownMenu : PulldownMenu <PulldownMenuDelegate>

@property (strong, nonatomic) NSArray* menuItemNames;

@end
