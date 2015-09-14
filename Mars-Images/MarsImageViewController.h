//
//  MarsImageViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 10/26/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MWPhotoBrowser.h"
#import "MarsPhoto.h"
#import "MMDrawerController.h"

@interface MarsImageViewController : MWPhotoBrowser<MWPhotoBrowserDelegate>

@property (strong, nonatomic) UIBarButtonItem*        imageSelectionButton;
@property (strong, nonatomic) UIBarButtonItem*        shareButton;
@property (strong, nonatomic) UISegmentedControl*     segmentedControl;
@property (strong, nonatomic) MMDrawerController*     drawerController;

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

+ (UIColor*)defaultSystemTintColor; //IOS 7 only

- (void) notesLoaded: (NSNotification*) notification;
- (MarsPhoto*) currentPhoto;

- (void) imageSelected: (NSNotification*) notification;
- (IBAction) toggleTableView: (id)sender;
- (void) configureToolbarAndNavbar;
- (void) imageSelectionButtonPressed: (id)sender;
- (void) segmentedControlButtonPressed: (id)sender;
@end
