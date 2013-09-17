//
//  DetailViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Evernote.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *toolbarButtonView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
- (IBAction)refreshButtonPress:(id)sender;
- (IBAction)imageButtonPressed:(id)sender;
- (void) hideMasterView;
@property (strong, nonatomic) EDAMNote *note;
@property                     BOOL showMaster;

@end
