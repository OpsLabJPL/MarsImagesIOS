//
//  MarsViewDeck.m
//  Mars-Images
//
//  Created by Mark Powell on 12/16/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsSidePanelController.h"
#import "MarsImageNotebook.h"
#import "MarsImageTableViewController.h"

#define LEFT_PANEL_WIDTH 200

@interface MarsSidePanelController ()

@end

@implementation MarsSidePanelController

- (void) viewDidLoad {
    
    [super viewDidLoad];
    NSLog(@"Side panel controller loaded.");
    UIStoryboard* storyboard = self.storyboard;
    
    UINavigationController* imageNavVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"imageNavController"];
    UINavigationController* tableVC = (UINavigationController*)[storyboard instantiateViewControllerWithIdentifier:@"tableNavController"];
    
    self.leftPanel = tableVC;
    self.centerPanel = imageNavVC;
    
    self.leftFixedWidth = LEFT_PANEL_WIDTH;
    self.shouldResizeLeftPanel = YES;
    
    //load first notes in background
    [[MarsImageNotebook instance] loadMoreNotes:0 withTotal:15];
}

- (void) imageSelected:(int)index
                  from:(UIViewController*) sender {
    _imageIndex = index;
    NSLog(@"Image %d was selected from %@.", index, sender);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:index], IMAGE_INDEX, sender, SENDER, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:IMAGE_SELECTED object:nil userInfo:dict];
}

- (void)stylePanel:(UIView *)panel {
    [super stylePanel:panel];
    panel.layer.cornerRadius = 0.0f;
}

@end
