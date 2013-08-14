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

#define TITLE_PREFIX @"Mars Images: "

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController
@synthesize infoButton;
@synthesize reloading;

static NSString* currentMission;
NSString* previousSearch;

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    //load first notes in background
    [[MarsNotebook instance] loadMoreNotes:0 withTotal:15
                        withNavigationItem:[self navigationItem]
                             withController:self];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    currentMission = [prefs stringForKey:@"mission"];
    self.title = [TITLE_PREFIX stringByAppendingString:currentMission];
    
    // Uncomment the following line to disable preservation of selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // add pull to refresh
    if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		view.delegate = self;
		[self.tableView addSubview:view];
		_refreshHeaderView = view;		
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    
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
    [self setInfoButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void) awakeFromNib {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton setImage:button.currentImage];
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
    if ([[segue identifier] isEqualToString:@"viewImageFullscreen"]) {
        FullscreenImageViewController *vc = [segue destinationViewController];
        NSIndexPath *path = [[self tableView] indexPathForSelectedRow];
        NSString *noteGUID = [[MarsNotebook instance].noteGUIDs objectAtIndex: path.row];
        [vc setNoteGUID: noteGUID];
    } else if ([[segue identifier] isEqualToString:@"coursePlotFromTableCell"]) {
        CoursePlotViewController* vc = segue.destinationViewController;
        NSIndexPath *path = [[self tableView] indexPathForSelectedRow];
        NSString* selectedTitle = [[[MarsNotebook instance] noteTitles] objectAtIndex:path.row];
        NSMutableArray* tokens = (NSMutableArray*)[selectedTitle componentsSeparatedByString:@" "];
        int sol = [[tokens objectAtIndex:1] integerValue];
        [vc setSolDirectory: [NSString stringWithFormat:@"%03d", sol ]];
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
    NSArray *chunks = [cellValue componentsSeparatedByString: @" "];
    int sol = [[chunks objectAtIndex: 1] intValue];
    NSString* imageID = nil;
    if ([chunks count] < 4) {
        imageID = [chunks objectAtIndex:2];
    }
    else {
        imageID = [chunks objectAtIndex:[MarsNotebook instance].titleImageIdPosition];
    }
    
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
    if (self.detailViewController) {
        NSIndexPath *path = [[self tableView] indexPathForSelectedRow];
        NSString *noteGUID = [[MarsNotebook instance].noteGUIDs objectAtIndex: path.row];
        [self.detailViewController setDetailItem: noteGUID];
    }
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	[self reloadImages:nil];
}

- (void)doneLoadingTableViewData{
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];	
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return reloading; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date]; // should return date data source was last changed
}

@end
