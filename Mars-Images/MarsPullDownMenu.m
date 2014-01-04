//
//  MarsPullDownMenu.m
//  Mars-Images
//
//  Created by Mark Powell on 12/28/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsPullDownMenu.h"
#import "MarsImageNotebook.h"

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
    [array addObject: CURIOSITY];
    [array addObject: OPPORTUNITY];
    [array addObject: SPIRIT];
    _menuItemNames = array;
    
    return self;
}

- (void) setSelectedMenuItemName: (NSString*) itemName {
    int i = 0;
    for (NSString* item in self.menuItemNames) {
        if ([item isEqualToString:itemName]) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.menuList selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            return;
        }
        i++;
    }
}

- (void) pullDownAnimated:(BOOL)open {
    //nothing needed here
}

- (void)menuItemSelected:(NSIndexPath *)indexPath {
    NSString* chosenMission = [menuItems objectAtIndex:indexPath.item];
    if (!([chosenMission isEqualToString:[MarsImageNotebook instance].missionName])) {
        
        /* update current mission for app internally */
//        [MarsImageNotebook instance].missionName = chosenMission;
        
        /* update current mission in app settings (informs listeners to refresh UI) */
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:chosenMission forKey:MISSION];
        [prefs synchronize];
    }
    [self animateDropDown];
}

@end
