//
//  MarsViewDeck.m
//  Mars-Images
//
//  Created by Mark Powell on 12/16/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsSidePanelController.h"
#import "IISideController.h"
#import "MarsImageNotebook.h"
#import "MarsImageViewController.h"

#define LEFT_PANEL_WIDTH 275

@interface MarsSidePanelController ()

@end

@implementation MarsSidePanelController

- (void) viewDidLoad {
    [super viewDidLoad];
    [self setDelegate: self];
    [self configureLeftPanel: [UIApplication sharedApplication].statusBarOrientation];
    //load first notes in background
    [[MarsImageNotebook instance] loadMoreNotes:0 withTotal:15];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self configureLeftPanel:toInterfaceOrientation];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) configureLeftPanel: (UIInterfaceOrientation) interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        [self setLeftSize:0.25]; //nearly zero but not quite makes the table view invisible in portrait mode without making the ViewDeck flip out and resize the image view badly :)
    }
    else {
        [self setLeftSize:LEFT_PANEL_WIDTH];
    }
}

- (void) imageSelected:(int)index
                  from:(UIViewController*) sender {
    _imageIndex = index;
    NSLog(@"Image %d was selected from %@.", index, sender);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:index], IMAGE_INDEX, sender, SENDER, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:IMAGE_SELECTED object:nil userInfo:dict];
}

#pragma mark IIViewDeckControllerDelegate

- (void) viewDeckController:(IIViewDeckController *)viewDeckController didCloseViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    for (UIViewController* vc in self.centerController.childViewControllers) {
        if ([vc isKindOfClass:[MarsImageViewController class]]) {
            [(MarsImageViewController*)vc configureToolbarAndNavbar];
        }
    }
}

- (void) viewDeckController:(IIViewDeckController *)viewDeckController didOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    for (UIViewController* vc in self.centerController.childViewControllers) {
        if ([vc isKindOfClass:[MarsImageViewController class]]) {
            [(MarsImageViewController*)vc configureToolbarAndNavbar];
        }
    }
}

@end
