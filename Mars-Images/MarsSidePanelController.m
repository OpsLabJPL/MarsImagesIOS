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
#import "MarsImageTableViewController.h"

#define LEFT_PANEL_WIDTH 256
#define LEFT_PANEL_NARROW_WIDTH 56

@interface MarsSidePanelController ()

@end

@implementation MarsSidePanelController

- (void) viewDidLoad {
    
    [super viewDidLoad];
    NSLog(@"Side panel controller loaded.");
    UIStoryboard* storyboard = self.storyboard;
    
    UINavigationController* imageNavVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"imageNavController"];
    UINavigationController* tableVC = (UINavigationController*)[storyboard instantiateViewControllerWithIdentifier:@"tableNavController"];
    
    self.centerController = imageNavVC;
    self.leftController = [[IISideController alloc] initWithViewController:tableVC];
   
    self.resizesCenterView = YES;
    [self setLeftPanelWidth: [UIApplication sharedApplication].statusBarOrientation];
    self.sizeMode = IIViewDeckViewSizeMode;
    
    //load first notes in background
    [[MarsImageNotebook instance] loadMoreNotes:0 withTotal:15];
}

//- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    NSLog(@"rotated to orientation %d", [UIApplication sharedApplication].statusBarOrientation);
//    [self setLeftPanelWidth: [UIApplication sharedApplication].statusBarOrientation];
//}

- (void) setLeftPanelWidth: (UIInterfaceOrientation) interfaceOrientation {
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(width, height);
    } else {
        screenBounds.size = CGSizeMake(height, width);
    }
    int screenWidth = screenBounds.size.width;
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        self.leftSize = screenWidth - LEFT_PANEL_NARROW_WIDTH;
    else
        self.leftSize = screenWidth - LEFT_PANEL_WIDTH;
}

- (void) imageSelected:(int)index
                  from:(UIViewController*) sender {
    _imageIndex = index;
    NSLog(@"Image %d was selected from %@.", index, sender);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:index], IMAGE_INDEX, sender, SENDER, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:IMAGE_SELECTED object:nil userInfo:dict];
}

@end
