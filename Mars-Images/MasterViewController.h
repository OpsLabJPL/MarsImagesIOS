//
//  MasterViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <EGORefreshTableHeaderDelegate> {
	EGORefreshTableHeaderView *_refreshHeaderView;
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

- (void) doneLoadingTableViewData; //pull to refresh

- (void) scrollViewDidScroll:(UIScrollView *) scrollView;

- (void) scrollViewDidEndDragging:(UIScrollView *) scrollView willDecelerate:(BOOL)decelerate;

- (void) egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view;

- (BOOL) egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view;

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view;

@end
