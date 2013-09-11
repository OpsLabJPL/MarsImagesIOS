//
//  DetailViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "DetailViewController.h"
#import "Evernote.h"
#import "MarsNotebook.h"
#import "UIImage+Resize.h"
#import "FullscreenImageViewController.h"
#import "CoursePlotViewController.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

@synthesize note;
@synthesize toolbarButtonView;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (_detailItem == nil)
        return;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    // Set to Left or Right
    [[self navigationItem] setRightBarButtonItem:barButton];
    [spinner startAnimating];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("image note preview downloader", NULL);
    dispatch_async(downloadQueue, ^{
        if (note == nil || !([[note guid] isEqualToString:(NSString *) _detailItem])) {
            [self setNote: [[MarsNotebook instance] getNote: _detailItem]];
            if (note == nil)
                return;
        }
        if ([note.resources count] > 0) {
            //look for the first JPEG resource for our image view
            for (int i=0; i < note.resources.count; i++) {
                EDAMResource * resource = [note.resources objectAtIndex:i];
                
                if ([resource.mime isEqualToString: @"image/jpeg"] || [resource.mime isEqualToString: @"image/png"]) {
                    UIImage* tmpImage = [[UIImage alloc] initWithData:resource.data.body];
                    
                    /* resize the image properly for the detail view area, centered and sized to maintain the original aspect ratio while also using either all horizontal or all vertical space (or both) without distorting the image or making it necessary to scroll the image */
                    float xScale = [[self view] frame].size.width / (float)tmpImage.size.width;
                    float yScale = [[self view] frame].size.height / (float)tmpImage.size.height;
                    int newWidth = tmpImage.size.width;
                    int newHeight = tmpImage.size.height;
                    newWidth *= MIN(xScale, yScale);
                    newHeight *= MIN(xScale, yScale);
                    UIImage* resizedImage = [tmpImage resizedImage:CGSizeMake(newWidth, newHeight) interpolationQuality:kCGInterpolationHigh];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.imageButton setImage:resizedImage forState: UIControlStateNormal];
                        int x = 0;
                        int y = ([[self view] frame].size.height - resizedImage.size.height) / 2;
                        self.imageButton.frame = CGRectMake(x, y, resizedImage.size.width, resizedImage.size.height);

                        [self.navigationItem setRightBarButtonItem:nil];
                        [spinner stopAnimating];
                    });
                    break; //...there can be only one (JPEG)
                }
            }
        }
    });
}

- (void)awakeFromNib {
    //make sure master view is showing on initialization
    self.showMaster = YES;
    self.note = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    //make sure master view will show after fullscreen image view is popped off and this view reappears
    self.showMaster = YES;
    
    //force UISplitViewController to hide the master based on the showMaster flag
    //all this to avoid having a dependency on MGSplitViewController
    [self.splitViewController.view setNeedsLayout];
    [self.splitViewController setDelegate: nil];
    [self.splitViewController setDelegate: self];
    [self.splitViewController willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

//IOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

//IOS 6
- (NSUInteger) supportedOrientationsForWindow {
    return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self configureView];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //resize the preview image for view size in the new orientation, avoid wonky-looking animated scaling
    [self configureView];
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"viewImageFullscreen"])
        return note != nil;
    
    return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewImageFullscreen"]) {
        FullscreenImageViewController *vc = [segue destinationViewController];
        [vc setNoteGUID: note.guid];
        [vc setNote: note];
        [self hideMasterView];
    } else if ([[segue identifier] isEqualToString:@"coursePlotFromDetail"]) {
        CoursePlotViewController* vc = segue.destinationViewController;
        NSArray *vcs = self.splitViewController.viewControllers;
        UINavigationController *nc = [vcs objectAtIndex:0];
        MasterViewController *mvc = [nc.childViewControllers objectAtIndex:0];
        NSIndexPath *path = [[mvc tableView] indexPathForSelectedRow];
        NSString* selectedTitle = [[[MarsNotebook instance] noteTitles] objectAtIndex:path.row];
        NSMutableArray* tokens = (NSMutableArray*)[selectedTitle componentsSeparatedByString:@" "];
        int sol = [[tokens objectAtIndex:1] integerValue];
        [vc setSolDirectory: [NSString stringWithFormat:@"%03d", sol ]];
        [self hideMasterView];
    } else if ([[segue identifier] isEqualToString:@"about"]) {
        [self hideMasterView];
    }
}

- (void) hideMasterView {
    self.showMaster = NO;
    //force UISplitViewController to hide the master based on the showMaster flag
    //all this to avoid having a dependency on MGSplitViewController
    [self.splitViewController.view setNeedsLayout];
    [self.splitViewController setDelegate: nil];
    [self.splitViewController setDelegate: self];
    [self.splitViewController willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return !_showMaster;
}

- (void)viewDidUnload {
    [self setImageButton:nil];
    [self setToolbarButtonView:nil];
    [super viewDidUnload];
}

- (IBAction)refreshButtonPress:(id)sender {
    NSArray *vcs = self.splitViewController.viewControllers;
    UINavigationController *nc = [vcs objectAtIndex:0];
    MasterViewController *vc = [nc.childViewControllers objectAtIndex:0];
    [vc reloadImages:nil];
}

- (IBAction)imageButtonPressed:(id)sender {
    NSArray *vcs = self.splitViewController.viewControllers;
    UINavigationController *nc = [vcs objectAtIndex:0];
    MasterViewController *mvc = [nc.childViewControllers objectAtIndex:0];
    NSIndexPath* path = [[mvc tableView] indexPathForSelectedRow];
    UITableViewCell *cell = [[mvc tableView] cellForRowAtIndexPath:path];
    if ([cell.reuseIdentifier isEqualToString:@"ImageCell"])
        [self performSegueWithIdentifier:@"viewImageFullscreen" sender:sender];
    else if ([cell.reuseIdentifier isEqualToString:@"CoursePlotCell"])
        [self performSegueWithIdentifier:@"coursePlotFromDetail" sender:sender];
    else
        NSLog(@"Error: unexpected cell identifier when detail view image button was pressed: %@", cell.reuseIdentifier);
}
@end
