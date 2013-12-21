//
//  MarsImageViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 10/26/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsImageViewController.h"
#import "Evernote.h"
#import "MarsImageNotebook.h"
#import "MarsRovers.h"
#import "MarsSidePanelController.h"
#import "PSMenuItem.h"
#import "UIViewController+JASidePanel.h"

@interface MarsImageViewController ()

@end

@implementation MarsImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"setting image view delegate.");
        self.delegate = self;
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSLog(@"setting image view delegate.");
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIButton* imageNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [imageNameButton setTitle:@"FooBarBaz" forState:UIControlStateNormal];
    [imageNameButton addTarget:self action:@selector(imageSelectionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    imageNameButton.frame = CGRectMake(0,0,100,44);
    _imageSelectionButton = [[UIBarButtonItem alloc] initWithCustomView:imageNameButton];

    [PSMenuItem installMenuHandlerForObject:self];
    self.wantsFullScreenLayout = NO; //otherwise we get a nasty gap between the nav and status bar
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesLoaded:) name:END_NOTE_LOADING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageSelected:) name:IMAGE_SELECTED object:nil];
}

- (void)viewDidLayoutSubviews {
    [self configureToolbarAndNavbar];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) toggleTableView: (id)sender {
    [self.sidePanelController toggleLeftPanel:self];
}

- (void) notesLoaded: (NSNotification*) notification {
    int numNotesReturned = 0;
    NSNumber* num = [notification.userInfo objectForKey:NUM_NOTES_RETURNED];
    if (num != nil) {
        numNotesReturned = [num intValue];
    }
    NSLog(@"Image view notified of %d notes loaded.", numNotesReturned);
    if (numNotesReturned > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }
}

- (void) imageSelected: (NSNotification*) notification {
    NSNumber* num = [notification.userInfo valueForKey:IMAGE_INDEX];
    int index = [num intValue];
    UIViewController* sender = [notification.userInfo valueForKey:SENDER];
    NSLog(@"in image view, image %d is current and image %d needs to be selected.", [self currentIndex], index);
    if (sender != self && index != [self currentIndex]) {
        [self setCurrentPhotoIndex: index];
    }
}

- (void) imageSelectionButtonPressed: (id)sender {
    int noteIndex = [self currentIndex];
    NSArray* resources = [[MarsImageNotebook instance] getResources:noteIndex];
    if (!resources || [resources count] <=1) {
        return;
    }
    
    int resourceIndex = 0;
    NSMutableArray* menuItems = [[NSMutableArray alloc] init];
    for (EDAMResource* resource in resources) {
        NSLog(@"First resource %@", resource.guid);
        PSMenuItem *menuItem = [[PSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", resourceIndex]
                                                           block:^{
                                                               NSLog(@"change to image %d", resourceIndex);
                                                               [[MarsImageNotebook instance] changeToImage:resourceIndex forNote:noteIndex];
                                                               [self reloadData];
                                                           }];
        [menuItems addObject:menuItem];
        resourceIndex+=1;
    }
    if ([menuItems count] > 1) {
        [UIMenuController sharedMenuController].menuItems = menuItems;
        [[UIMenuController sharedMenuController] setTargetRect:_imageSelectionButton.customView.bounds inView:_imageSelectionButton.customView];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
    }
    
}

- (void) configureToolbarAndNavbar {
    for (UIView* view in [self.view subviews]) {
        BOOL isToolbar = [view isKindOfClass:[UIToolbar class]];
        if (isToolbar) {
            [(UIToolbar*)view setItems:[NSArray arrayWithObjects:_imageSelectionButton, nil]];
        }
    }
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.title = nil;
}

#pragma mark MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [MarsImageNotebook instance].notePhotos.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    return [[MarsImageNotebook instance].notePhotos objectAtIndex:index];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    
    [self configureToolbarAndNavbar];
    
    int count = [MarsImageNotebook instance].notePhotos.count;
    if (index == count-1) {
        [[MarsImageNotebook instance] loadMoreNotes:count withTotal:15];
    }
    [(MarsSidePanelController*)self.sidePanelController imageSelected:index from:self];
}

@end
