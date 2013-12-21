//
//  MasterViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "MarsNotebook.h"
#import "FixedWidthImageTableViewCell.h"
#import "FullscreenImageViewController.h"
#import "CoursePlotViewController.h"
#import "MWPhotoBrowser.h"
#import "MarsImageCaptionView.h"

#define TITLE_PREFIX @""

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController
@synthesize reloading;
@synthesize selectedRow;

static NSString* currentMission;
NSString* previousSearch;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadTableViewDataSource) forControlEvents:UIControlEventValueChanged];
    [refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Updating"]];
    self.refreshControl = refreshControl;

    //load first notes in background
    [[MarsNotebook instance] loadMoreNotes:0 withTotal:15
                        withNavigationItem:[self navigationItem]
                             withController:self];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    currentMission = [prefs stringForKey:@"mission"];
    self.title = [TITLE_PREFIX stringByAppendingString:currentMission];
    
    // Uncomment the following line to disable preservation of selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    //listen for preference changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForegroundAfterLongSleep:) name:@"EnteredForeground" object:nil];
}

- (void) enteredForegroundAfterLongSleep:(id)object {
    [self reloadImages: nil];
}

- (void) viewWillAppear:(BOOL)animated {
        
    //if the view appears after popping back from search, reload the table view using the new search (if any)
    NSString* currentSearch = [[MarsNotebook instance] searchWords];
    if (currentSearch != nil && (previousSearch == nil || ![currentSearch isEqualToString:previousSearch])) {
        previousSearch = currentSearch;
        [self reloadImagesImpl]; //don't clear search
    }
}

- (void) viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void) awakeFromNib {
}

- (IBAction) reloadButton:(id)sender {
    [self reloadImages:sender];
}

- (void) defaultsChanged:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *mission = [prefs stringForKey:@"mission"];
    if ( ! [mission isEqualToString:currentMission]) {
        //set the view title to reflect the mission
        currentMission = mission;
        self.title = [TITLE_PREFIX stringByAppendingString:mission];
        [self reloadImages:nil];
    }
}

- (void) reloadImages:(id)sender {
    [MarsNotebook instance].searchWords = nil;
    [self reloadImagesImpl];
}

- (void) reloadImagesImpl {
    //clear all notes out of app delegate, scroll table to top and start over loading images
    [[[MarsNotebook instance] noteTitles ] removeAllObjects];
    [[[MarsNotebook instance] noteGUIDs ] removeAllObjects];
    [[[MarsNotebook instance] notePhotos] removeAllObjects];
    [[self tableView] reloadData];
    //reload the initial set of notes
    [[MarsNotebook instance] loadMoreNotes:0 withTotal:15
                        withNavigationItem:[self navigationItem]
                            withController:self]; 
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([[segue identifier] isEqualToString:@"viewImageFullscreen"]) {
//        FullscreenImageViewController *vc = [segue destinationViewController];
//        NSIndexPath *path = [[self tableView] indexPathForSelectedRow];
//        NSString *title = [[MarsNotebook instance].noteTitles objectAtIndex: path.row];
//        NSString *noteGUID = [[MarsNotebook instance].noteGUIDs objectForKey: title];
//        [vc setNoteGUID: noteGUID];
//        NSString *anaglyphTitle = [[MarsNotebook instance] getAnaglyphTitle: title];
//        [vc setAnaglyphNoteGUID: [[MarsNotebook instance].noteGUIDs objectForKey: anaglyphTitle]];
//    } else if ([[segue identifier] isEqualToString:@"coursePlotFromTableCell"]) {
//        CoursePlotViewController* vc = segue.destinationViewController;
//        NSIndexPath *path = [[self tableView] indexPathForSelectedRow];
//        NSString* selectedTitle = [[[MarsNotebook instance] noteTitles] objectAtIndex:path.row];
//        NSMutableArray* tokens = (NSMutableArray*)[selectedTitle componentsSeparatedByString:@" "];
//        int sol = [[tokens objectAtIndex:1] integerValue];
//        [vc setSolDirectory: [NSString stringWithFormat:@"%03d", sol ]];
//    }
    if ([[segue identifier] isEqualToString:@"swiper"]) {
        MWPhotoBrowser* browser = [segue destinationViewController];
        
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.wantsFullScreenLayout = YES;
        browser.zoomPhotosToFill = YES;

        [browser setDelegate:self];
        UITableViewCell *cell = (UITableViewCell*) sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [browser setCurrentPhotoIndex: indexPath.row];
    }
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[MarsNotebook instance] noteTitles] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = nil;
    NSString* title = [[[MarsNotebook instance] noteTitles] objectAtIndex:indexPath.row];
    if ([title rangeOfString:@"Course"].location != NSNotFound)
        CellIdentifier = @"CoursePlotCell";
    else
        CellIdentifier = @"ImageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FixedWidthImageTableViewCell alloc] init];
    }
    else {
        [cell.imageView setImage:nil];
    }
    
    NSString *cellValue = [[[MarsNotebook instance] noteTitles] objectAtIndex:indexPath.row];
    //returns "Sol 1234 1F123456789EFF...". We want the last bit.
    NSString* imageID = [[MarsNotebook instance] getImageIDForTitle: cellValue];
    int sol = [[MarsNotebook instance] getSolForTitle: cellValue];
    [cell.textLabel setText: [[MarsNotebook instance] getUpperCellText: imageID withTitle:cellValue]];
    [cell.detailTextLabel setText: [[MarsNotebook instance] getLowerCellText: imageID withSol: sol]];
    
    [[MarsNotebook instance] startThumbnailLoaderThread: imageID withCell: cell withSol: sol];
    
    //check whether we're at the end of the list and if so try to load more images/notes
    int count = [[[MarsNotebook instance] noteTitles] count];
    if (count - 1 == [indexPath row]) {
        [[MarsNotebook instance] loadMoreNotes:count
                                     withTotal:15
                            withNavigationItem:[self navigationItem]
                                 withController:self];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedRow = indexPath.row;
    if (self.detailViewController) {
        NSIndexPath *path = [[self tableView] indexPathForSelectedRow];
        NSString *title = [[MarsNotebook instance].noteTitles objectAtIndex: path.row];
        NSString *noteGUID = [[MarsNotebook instance].noteGUIDs objectForKey: title];
        [self.detailViewController setDetailItem: noteGUID];
    }
}

#pragma mark-
#pragma mark MWPhotoBrowserDelegate methods

- (NSUInteger) numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [[[MarsNotebook instance] noteTitles] count];
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    return [[[MarsNotebook instance] notePhotos] objectAtIndex:index];
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [[[MarsNotebook instance] notePhotos] objectAtIndex:index];
//    MarsImageCaptionView *captionView = [[MarsImageCaptionView alloc] initWithPhoto:photo];
//    return captionView;
//}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	[self reloadImages:nil];
    [self.refreshControl endRefreshing];
}

@end
