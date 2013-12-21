//
//  MasterViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MWPhotoBrowser.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController <MWPhotoBrowserDelegate> {
}

@property BOOL reloading;
@property (strong, nonatomic) DetailViewController *detailViewController;

- (void) defaultsChanged:(id)sender;

- (void) enteredForegroundAfterLongSleep:(id)sender;

- (void) reloadImages:(id)sender;

- (void) reloadImagesImpl;

- (void) reloadTableViewDataSource; //pull to refresh

@end
