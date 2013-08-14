//
//  FullscreenImageViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Evernote.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface FullscreenImageViewController : UIViewController <UIScrollViewDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) NSString* noteGUID;
@property (strong, nonatomic) EDAMNote* note;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *coursePlotButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *coursePlotFlexibleSpace;
@property (weak, nonatomic) IBOutlet UIButton *iPadCoursePlotButton;

- (IBAction) mailImage: (id) sender;

@end
