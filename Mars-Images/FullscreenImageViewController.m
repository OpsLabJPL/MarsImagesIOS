//
//  FullscreenImageViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "FullscreenImageViewController.h"
#import "ImageInfoTextViewController.h"
#import "CoursePlotViewController.h"
#import "MarsNotebook.h"

@interface FullscreenImageViewController ()

@end

@implementation FullscreenImageViewController

@synthesize noteGUID;
@synthesize note;
@synthesize coursePlotButton;
@synthesize coursePlotFlexibleSpace;
@synthesize iPadCoursePlotButton;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    NSString* currentMission = [MarsNotebook instance].currentMission;
    
    //set the initial visibility of the course plot button: shown if mission is Oppy or Spirit, hidden if not
    if (!([currentMission isEqualToString:@"Opportunity"] || [currentMission isEqualToString:@"Spirit"])) {
        if (iPadCoursePlotButton) { //on the iPad this button lives on the detailViewController
            iPadCoursePlotButton.hidden = YES;
        } else { //on the iPhone this button lives in our own toolbar
            NSMutableArray* newItemsInToolbar = [[NSMutableArray alloc] initWithArray:[self toolbarItems]];
            [newItemsInToolbar removeObjectIdenticalTo: coursePlotButton];
            [newItemsInToolbar removeObjectIdenticalTo: coursePlotFlexibleSpace];
            [self setToolbarItems:newItemsInToolbar animated:YES];
        }
    }

    // anti-IB-autolayout: needed to prevent jerky zoom behavior with imageView contained in scrollView
    [self.imageView removeConstraints:self.imageView.constraints];
    [self.scrollView removeConstraints:self.scrollView.constraints];
    self.imageView.translatesAutoresizingMaskIntoConstraints = YES;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self loadMyImage];
}

// we need this in addition to anti-IB-autolayoutto counter jerky zoom behavior
- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
    CGRect cFrame = self.imageView.frame;
    cFrame.origin = CGPointZero;
    self.imageView.frame = cFrame;
}

- (void) viewDidUnload {
    [self setImageView:nil];
    [self setScrollView:nil];
    [self setInfoButton:nil];
    [self setCoursePlotButton:nil];
    [self setCoursePlotFlexibleSpace:nil];
    [self setIPadCoursePlotButton:nil];
    [super viewDidUnload];
}

- (void) awakeFromNib {
    //set the info icon image on the info button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [self.infoButton setImage:button.currentImage];
}

#pragma mark - device rotation support

- (NSUInteger) supportedInterfaceOrientationsForWindow {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - fetch an image and display

- (void) loadMyImage {
    if (!noteGUID && !note)
        return;
    
    UIActivityIndicatorView *spinner = nil;

    if (!note) { //start a progress spinner for the async download
        spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        [[self navigationItem] setRightBarButtonItem:barButton];
        [spinner startAnimating];
    }
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("image note downloader", NULL);
    dispatch_async(downloadQueue, ^{
        if (!note) { //async load the image note from Evernote in an I/O thread
            [self setNote: [[MarsNotebook instance] getNote: noteGUID]];
            if (!note) return;
        }
        if ([note.resources count] > 0) { //look for the first JPEG resource for our image view
            for (int i=0; i < note.resources.count; i++) {
                EDAMResource * resource = [note.resources objectAtIndex:i];
                
                if ([resource.mime isEqualToString: @"image/jpeg"] || [resource.mime isEqualToString:@"image/png"]) {
                    UIImage* tmpImage = [[UIImage alloc] initWithData:resource.data.body];
                    dispatch_async(dispatch_get_main_queue(), ^{ // Assign image to view in UI thread
                        self.imageView.image = tmpImage;
                        self.scrollView.contentSize = self.imageView.bounds.size;
                        
                        if (spinner) { //end progress spinner
                            [[self navigationItem] setRightBarButtonItem:nil];
                            [spinner stopAnimating];
                        }
                    });
                    break; //...there can be only one (JPEG)
                }
            }
        }
    });
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return note != nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"imageInfo"]) {
        ImageInfoTextViewController *vc = segue.destinationViewController;
        if (note)
            [vc setNote: note];
    } else if ([[segue identifier] isEqualToString:@"coursePlot"]) {
        CoursePlotViewController *vc = segue.destinationViewController;
        if (note) {
            NSString* sol = [[MarsNotebook instance] getSolForNote:note];
            [vc setSolDirectory: sol];
            [vc setNote: note];
        }
    }
}

- (IBAction) mailImage:(id)sender {
    if (!self.imageView.image) return;
    
    NSString* mission = [MarsNotebook instance].currentMission;
    //present a modal MFMailComposeViewController here
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    NSString* noteTitle = note.title;
    [controller setSubject: [NSString stringWithFormat: @"%@ image %@", mission, noteTitle]];
    [controller setMessageBody:[NSString stringWithFormat: @"%@ image %@ sent from Mars images", mission, noteTitle] isHTML:YES];
    NSData* imageData = UIImageJPEGRepresentation(self.imageView.image, 1.0);
    [controller addAttachmentData: imageData
                         mimeType: @"image/jpeg"
                         fileName: [NSString stringWithFormat:@"%@.JPG", noteTitle]];
    if (controller) [self presentViewController:controller animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - scroll view delegate

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
