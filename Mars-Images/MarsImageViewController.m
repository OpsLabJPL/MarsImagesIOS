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
        self.delegate = self;
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
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
    _imageNameButton.frame = CGRectMake(0,0,150,44);
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
    if (num) {
        numNotesReturned = [num intValue];
    }
    if (numNotesReturned > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }
}

- (MarsPhoto*) currentPhoto {
    NSArray* photos = [MarsImageNotebook instance].notePhotosArray;
    if (photos.count == 0)
        return nil;
    return (MarsPhoto*)[photos objectAtIndex:self.currentIndex];
}

- (void) imageSelected: (NSNotification*) notification {
    NSNumber* num = [notification.userInfo valueForKey:IMAGE_INDEX];
    int index = [num intValue];
    UIViewController* sender = [notification.userInfo valueForKey:SENDER];
    if (sender != self && index != [self currentIndex]) {
        [self setCurrentPhotoIndex: index];
    }
    [self configureToolbarAndNavbar];
}

- (void) imageSelectionButtonPressed: (id)sender {
    [self becomeFirstResponder];
    NSArray* resources = [self currentPhoto].note.resources;
    if (!resources || resources.count <=1) {
        return;
    }
    
    int resourceIndex = 0;
    NSMutableArray* menuItems = [[NSMutableArray alloc] init];
    for (EDAMResource* resource in resources) {
        NSString* imageName = [[MarsImageNotebook instance].mission imageName:resource];
        PSMenuItem *menuItem = [[PSMenuItem alloc] initWithTitle:imageName
                                                           block:^{
                                                               [[MarsImageNotebook instance] changeToImage:resourceIndex forNote:self.currentIndex];
                                                               [self reloadData];
                                                           }];
        [menuItems addObject:menuItem];
        resourceIndex += 1;
    }
    
    NSArray* leftAndRight = [[MarsImageNotebook instance].mission stereoForImages:resources];
    if (leftAndRight.count > 0) {
        PSMenuItem* menuItem = [[PSMenuItem alloc] initWithTitle:@"Anaglyph"
                                                             block:^{
                                                                 [[MarsImageNotebook instance] changeToAnaglyph: leftAndRight noteIndex:self.currentIndex];
                                                                 [self reloadData];
                                                             }];
        [menuItems addObject:menuItem];
    }
    
    if ([menuItems count] > 1) {
        [UIMenuController sharedMenuController].menuItems = menuItems;
        CGRect bounds = _imageSelectionButton.customView.bounds;
        [[UIMenuController sharedMenuController] setTargetRect:bounds inView:_imageSelectionButton.customView];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
    }
}

- (void) configureToolbarAndNavbar {
    int resourceCount = 0;
    MarsPhoto* photo = [self currentPhoto];
    resourceCount = photo.note.resources.count;
    for (UIView* view in [self.view subviews]) {
        BOOL isToolbar = [view isKindOfClass:[UIToolbar class]];
        if (isToolbar) {
            if (resourceCount > 1) {
                NSString* imageName = @"";
                if (photo.leftAndRight)
                    imageName = @"Anaglyph";
                else
                    imageName = [[MarsImageNotebook instance].mission imageName:photo.resource];
                [_imageNameButton setTitle:[NSString stringWithFormat:@"Filter: %@", imageName] forState:UIControlStateNormal];
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
    return [MarsImageNotebook instance].notePhotosArray.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    NSArray* photosArray = [MarsImageNotebook instance].notePhotosArray;
    if (photosArray.count > 0)
        return [photosArray objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    
    [self configureToolbarAndNavbar];
    
    int count = [MarsImageNotebook instance].notePhotosArray.count;
    if (index == count-1) {
        [[MarsImageNotebook instance] loadMoreNotes:count withTotal:15];
    }
    [(MarsSidePanelController*)self.viewDeckController imageSelected:index from:self];
}

@end
