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
@synthesize anaglyphNoteGUID;
@synthesize anaglyphNote;
@synthesize coursePlotButton;
@synthesize coursePlotFlexibleSpace;
@synthesize anaglyphButton;
@synthesize anaglyphFlexibleSpace;
@synthesize isAnaglyphDisplayMode;
@synthesize toolbarButtonItem;
@synthesize iPadToolbar;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    NSString* currentMission = [MarsNotebook instance].currentMission;
    
    //set the initial visibility of the course plot button: shown if mission is Oppy or Spirit, hidden if not
    if (!([currentMission isEqualToString:@"Opportunity"] || [currentMission isEqualToString:@"Spirit"])) {
        if (iPadToolbar) { //on the iPad this button lives on the detailViewController
            NSMutableArray* newItemsInToolbar = [[NSMutableArray alloc] initWithArray:iPadToolbar.items];
            [newItemsInToolbar removeObjectIdenticalTo: coursePlotButton];
            [newItemsInToolbar removeObjectIdenticalTo: coursePlotFlexibleSpace];
            iPadToolbar.items =  newItemsInToolbar;
        } else { //on the iPhone this button lives in our own toolbar
            NSMutableArray* newItemsInToolbar = [[NSMutableArray alloc] initWithArray:[self toolbarItems]];
            [newItemsInToolbar removeObjectIdenticalTo: coursePlotButton];
            [newItemsInToolbar removeObjectIdenticalTo: coursePlotFlexibleSpace];
            [self setToolbarItems:newItemsInToolbar animated:YES];
        }
    }
    //hide the anaglyph button if we don't have an image pair
    if (!anaglyphNoteGUID) {
        if (iPadToolbar) {
            NSMutableArray* newItemsInToolbar = [[NSMutableArray alloc] initWithArray: iPadToolbar.items];
            [newItemsInToolbar removeObjectIdenticalTo: anaglyphButton];
            [newItemsInToolbar removeObjectIdenticalTo: anaglyphFlexibleSpace];
            iPadToolbar.items = newItemsInToolbar;
        } else {
            NSMutableArray* newItemsInToolbar = [[NSMutableArray alloc] initWithArray:[self toolbarItems]];
            [newItemsInToolbar removeObjectIdenticalTo: anaglyphButton];
            [newItemsInToolbar removeObjectIdenticalTo: anaglyphFlexibleSpace];
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
    [self setAnaglyphButton: nil];
    [self setAnaglyphFlexibleSpace: nil];
    [self setIPadToolbar:nil];
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

- (void) loadMyAnaglyphImage {
    if (!anaglyphNoteGUID && !anaglyphNote)
        return;
    
    UIActivityIndicatorView *spinner = nil;
    
    if (!anaglyphNote) { //start a progress spinner for the async download
        spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        [[self navigationItem] setRightBarButtonItem:barButton];
        [spinner startAnimating];
    }
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("anaglyph note downloader", NULL);
    dispatch_async(downloadQueue, ^{
        if (!anaglyphNote) { //async load the image note from Evernote in an I/O thread
            [self setAnaglyphNote: [[MarsNotebook instance] getNote: anaglyphNoteGUID]];
            if (!anaglyphNote) return;
        }
        if ([anaglyphNote.resources count] > 0) { //look for the first JPEG resource for our image view
            for (int i=0; i < anaglyphNote.resources.count; i++) {
                EDAMResource * resource = [anaglyphNote.resources objectAtIndex:i];
                
                if ([resource.mime isEqualToString: @"image/jpeg"] || [resource.mime isEqualToString:@"image/png"]) {
                    UIImage* tmpImage = [[UIImage alloc] initWithData:resource.data.body];
                    dispatch_async(dispatch_get_main_queue(), ^{ // Assign image to view in UI thread

                        //set image view to anaglyph image here. Make sure left and right eyes are set properly.
                        NSString* imageID = [[MarsNotebook instance] getImageIDForTitle: anaglyphNote.title];
                        if ([[MarsNotebook instance] isImageIdLeftEye: imageID])
                            self.imageView.image = [self anaglyphImages: tmpImage right: self.imageView.image];
                        else
                            self.imageView.image = [self anaglyphImages: self.imageView.image right: tmpImage];
                        
                        self.scrollView.contentSize = CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height);
                        if (spinner) { //end progress spinner
                            [[self navigationItem] setRightBarButtonItem:nil];
                            [[self navigationItem] setRightBarButtonItem:toolbarButtonItem];
                            [spinner stopAnimating];
                        }
                    });
                    break; //...there can be only one (JPEG)
                }
            }
        }
    });
    dispatch_release(downloadQueue);
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

- (IBAction) toggleAnaglyphImage {
    if (!isAnaglyphDisplayMode && anaglyphNoteGUID) {
        [self loadMyAnaglyphImage];
        isAnaglyphDisplayMode = TRUE;
    } else {
        [self loadMyImage];
        isAnaglyphDisplayMode = FALSE;
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

#pragma mark - anaglyph image processing

- (UIImage*) anaglyphImages: (UIImage*)leftImage right:(UIImage*)rightImage {
    int width = (int)CGImageGetWidth(leftImage.CGImage);
    int height = (int)CGImageGetHeight(leftImage.CGImage);
    uint8_t* leftPixels = [self getGrayscalePixelArray:leftImage];
    uint8_t* rightPixels = [self getGrayscalePixelArray:rightImage];
    // now convert to anaglyph
    uint32_t *anaglyph = (uint32_t *) malloc(width * height * 4);
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint32_t leftRed = (uint32_t)leftPixels[y*width+x];
            uint32_t rightCyan = (uint32_t)rightPixels[y*width+x];
            anaglyph[y*width+x]=leftRed<<24 | rightCyan <<16 | rightCyan<<8;
        }
    }
    free(leftPixels);
    free(rightPixels);
    
    // create a UIImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(anaglyph, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:anaglyph length:width * height];
    return resultUIImage;
}

-(uint8_t*) getGrayscalePixelArray: (UIImage*)image {
    int width = (int)CGImageGetWidth(image.CGImage);
    int height = (int)CGImageGetHeight(image.CGImage);
    uint8_t *gray = (uint8_t *) malloc(width * height * sizeof(uint8_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(gray, width, height, 8, width, colorSpace, kCGColorSpaceModelMonochrome);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return gray;
}

@end
