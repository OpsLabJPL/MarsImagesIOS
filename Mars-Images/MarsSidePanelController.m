//
//  MarsViewDeck.m
//  Mars-Images
//
//  Created by Mark Powell on 12/16/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsSidePanelController.h"
//#import "IISideController.h"
#import "MarsImageNotebook.h"
#import "MarsImageViewController.h"

#define LEFT_PANEL_WIDTH 275

@interface MarsSidePanelController ()

@end

@implementation MarsSidePanelController

- (void) viewDidLoad {

    //load first notes in background
    [[MarsImageNotebook instance] loadMoreNotes:0 withTotal:NOTE_PAGE_SIZE];
    //load locations in background
    [[MarsImageNotebook instance] getLocations];
    [[MarsImageNotebook instance] getNamedLocations];
}

- (void) imageSelected:(int)index
                  from:(UIViewController*) sender {
    _imageIndex = index;
    NSLog(@"Image %d was selected from %@.", index, sender);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:index], IMAGE_INDEX, sender, SENDER, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:IMAGE_SELECTED object:nil userInfo:dict];
}

#pragma mark IIViewDeckControllerDelegate

//- (void) viewDeckController:(IIViewDeckController *)viewDeckController didCloseViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
//    for (UIViewController* vc in self.centerController.childViewControllers) {
//        if ([vc isKindOfClass:[MarsImageViewController class]]) {
//            [(MarsImageViewController*)vc configureToolbarAndNavbar];
//        }
//    }
//}
//
//- (void) viewDeckController:(IIViewDeckController *)viewDeckController didOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
//    for (UIViewController* vc in self.centerController.childViewControllers) {
//        if ([vc isKindOfClass:[MarsImageViewController class]]) {
//            [(MarsImageViewController*)vc configureToolbarAndNavbar];
//        }
//    }
//}

@end
