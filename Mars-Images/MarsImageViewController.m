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
#import "MarsPhoto.h"
#import "MarsSidePanelController.h"
#import "PSMenuItem.h"
#import "IIViewDeckController.h"

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
    _imageNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_imageNameButton setTitle:@"FooBarBaz" forState:UIControlStateNormal];
    [_imageNameButton addTarget:self action:@selector(imageSelectionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageNameButton.frame = CGRectMake(0,0,100,44);
    _imageSelectionButton = [[UIBarButtonItem alloc] initWithCustomView:_imageNameButton];

    [PSMenuItem installMenuHandlerForObject:self];
    self.wantsFullScreenLayout = NO; //otherwise we get an unsightly gap between the nav and status bar
    
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
    [self.viewDeckController toggleLeftViewAnimated:YES];
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
    [self configureToolbarAndNavbar];
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
        NSString* imageName = [[MarsImageNotebook instance].mission imageName:resource];
        PSMenuItem *menuItem = [[PSMenuItem alloc] initWithTitle:imageName
                                                           block:^{
                                                               [[MarsImageNotebook instance] changeToImage:resourceIndex forNote:noteIndex];
                                                               [self reloadData];
                                                           }];
        [menuItems addObject:menuItem];
        resourceIndex += 1;
    }
    
    if ([menuItems count] > 1) {
        [UIMenuController sharedMenuController].menuItems = menuItems;
        [[UIMenuController sharedMenuController] setTargetRect:_imageSelectionButton.customView.bounds inView:_imageSelectionButton.customView];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
    }
}

- (void) configureToolbarAndNavbar {
    int resourceCount = 0;
    MarsPhoto* photo;
    NSArray* notes = [MarsImageNotebook instance].notes;
    if (notes.count > 0) {
        EDAMNote* note = [[MarsImageNotebook instance].notes objectAtIndex:self.currentIndex];
        resourceCount = note.resources.count;
        photo = [[MarsImageNotebook instance].notePhotos objectAtIndex:[self currentIndex]];
    }
    for (UIView* view in [self.view subviews]) {
        BOOL isToolbar = [view isKindOfClass:[UIToolbar class]];
        if (isToolbar) {
            if (resourceCount > 1) {
                NSString* imageName = [[MarsImageNotebook instance].mission imageName:photo.resource];
                [_imageNameButton setTitle:imageName forState:UIControlStateNormal];
                [(UIToolbar*)view setItems:[NSArray arrayWithObjects:_imageSelectionButton, nil]];
            }
            else {
                [(UIToolbar*)view setItems:nil];
            }
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
    [(MarsSidePanelController*)self.viewDeckController imageSelected:index from:self];
}

@end
