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

#define LEFT_PANEL_WIDTH 256
#define LEFT_PANEL_NARROW_WIDTH 50

@interface MarsSidePanelController ()

@end

@implementation MarsSidePanelController

- (void) viewDidLoad {
    [super viewDidLoad];
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
        UIInterfaceOrientationIsPortrait(interfaceOrientation))
        self.leftSize = LEFT_PANEL_NARROW_WIDTH;
    else
        self.leftSize = LEFT_PANEL_WIDTH;
}

- (void) imageSelected:(int)index
                  from:(UIViewController*) sender {
    _imageIndex = index;
    NSLog(@"Image %d was selected from %@.", index, sender);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:index], IMAGE_INDEX, sender, SENDER, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:IMAGE_SELECTED object:nil userInfo:dict];
}

@end
