//
//  AboutViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem.title = @"";
    NSURL *url = [NSURL URLWithString: @"https://s3.amazonaws.com/www.powellware.net/MarsImagesiOS.html"];
    [self.webview loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) viewDidUnload {
    [self setWebview:nil];
    [self.navigationController setToolbarHidden:NO animated:YES];
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
