//
//  MasterViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController {
}

@property BOOL reloading;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;

- (IBAction)reloadButton:(id)sender;

- (void) defaultsChanged:(id)sender;

- (void) enteredForegroundAfterLongSleep:(id)sender;

- (void) reloadImages:(id)sender;

- (void) reloadImagesImpl;

- (void) reloadTableViewDataSource; //pull to refresh

@end
