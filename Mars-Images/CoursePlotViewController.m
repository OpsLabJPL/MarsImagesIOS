//
//  CoursePlotViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 5/8/13.
//  Copyright (c) 2013 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "CoursePlotViewController.h"
#import "ImageInfoTextViewController.h"
#import "MarsNotebook.h"

@interface CoursePlotViewController ()

@end

@implementation CoursePlotViewController
@synthesize solDirectory;
@synthesize note;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadMyImage];
}

- (void)viewDidUnload {
    [self setScrollView:nil];
    [self setImageView:nil];
    [super viewDidUnload];
}

#pragma mark - fetch a course plot image and display

- (void) loadMyImage {
    if (!solDirectory)
        return;
    
    UIActivityIndicatorView *spinner = nil;
    
    //start a progress spinner for the async download
    spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    [[self navigationItem] setRightBarButtonItem:barButton];
    [spinner startAnimating];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("course plot image downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSString* missionDir = @"";
        if ([[[MarsNotebook instance] currentMission] isEqualToString:@"Opportunity"])
            missionDir = @"merb";
        else if ([[[MarsNotebook instance] currentMission] isEqualToString:@"Spirit"])
            missionDir = @"mera";
        NSString* path = [NSString stringWithFormat:@"http://merpublic.s3.amazonaws.com/oss/%@/ops/ops/surface/tactical/sol/%@/sret/mobidd/mot-all-report/cache-mot-all-report/hyperplots/raw_north_vs_raw_east.png", missionDir, solDirectory];
        NSURL *url = [NSURL URLWithString:path];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *tmpImage = [[UIImage alloc] initWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{ // Assign image to view in UI thread
            self.imageView.image = tmpImage;
            self.scrollView.contentSize = CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height);
            if (spinner) { //end progress spinner
                [[self navigationItem] setRightBarButtonItem:nil];
                [spinner stopAnimating];
            }
        });
    });
}

#pragma mark - scroll view delegate

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
