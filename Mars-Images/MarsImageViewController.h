//
//  MarsImageViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 10/26/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MWPhotoBrowser.h"

@interface MarsImageViewController : MWPhotoBrowser<MWPhotoBrowserDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *tableViewButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *imageSelectionButton;

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
- (void) notesLoaded: (NSNotification*) notification;
- (void) imageSelected: (NSNotification*) notification;

- (IBAction) toggleTableView: (id)sender;

- (void) configureToolbarAndNavbar;

- (void) imageSelectionButtonPressed: (id)sender;

@end
