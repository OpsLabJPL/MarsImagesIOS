//
//  MarsImageTableViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 12/12/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsImageTableViewController.h"
#import "Evernote.h"
#import "FixedWidthImageTableViewCell.h"
#import "IIViewDeckController.h"
#import "MarsImageNotebook.h"
#import "MarsSidePanelController.h"
#import "UIImageView+WebCache.h"

#define IMAGE_CELL @"ImageCell"
#define SEARCH_CELL @"SearchCell"

@interface MarsImageTableViewController ()

@end

@implementation MarsImageTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Table view controller loaded");
    [self.tableView setScrollsToTop:YES];
    [self.searchDisplayController.searchResultsTableView setScrollsToTop:NO];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    //TODO get this selector right
    [refreshControl addTarget:self action:@selector(updateNotes) forControlEvents:UIControlEventValueChanged];
    [refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Updating"]];
    self.refreshControl = refreshControl;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString* currentMission = [prefs stringForKey:@"mission"];
    [_titleButton setTitle:currentMission forState:UIControlStateNormal];
    
    // Uncomment the following line to disable preservation of selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    _menu = [[MarsPullDownMenu alloc] initWithNavigationController:self.navigationController];
    [self.navigationController.view insertSubview:_menu belowSubview:self.navigationController.navigationBar];
    for (NSString* menuItemName in _menu.menuItemNames) {
         [_menu insertButton:menuItemName];
    }
    _menu.delegate = _menu;
    [_menu loadMenu];
    [_menu setSelectedMenuItemName:[MarsImageNotebook instance].missionName];
    
    //listen for preference changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForegroundAfterLongSleep:) name:@"EnteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesLoaded:) name:END_NOTE_LOADING object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageSelected:) name:IMAGE_SELECTED object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    UITableView* tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    [tableView reloadData];
    MarsSidePanelController* sidePanel = (MarsSidePanelController*)[self viewDeckController];
    [self selectAndScrollToRow:sidePanel.imageIndex];
}

- (IBAction)titleButtonPressed {
    UITableView* tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                     atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void) selectAndScrollToRow:(int)imageIndex {
    if (imageIndex < 0 || imageIndex >= [MarsImageNotebook instance].notesArray.count) {
        return;
    }
    UITableView* tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    EDAMNote* note = [[MarsImageNotebook instance].notesArray objectAtIndex:imageIndex];
    NSNumber* sol = [NSNumber numberWithInt:[[MarsImageNotebook instance].mission sol:note]];
    int section = ((NSNumber*)[[MarsImageNotebook instance].sections objectForKey:sol]).intValue;
    int rowIndex = 0;
    NSArray* notes = [[MarsImageNotebook instance].notes objectForKey:sol];
    for (EDAMNote* aNote in notes) {
        if (aNote == note)
            break;
        rowIndex++;
    }
    if (rowIndex == notes.count) return;
    
    // Get the cell rect and adjust it to consider scroll offset
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:section];
    NSIndexPath* selectedPath = [tableView indexPathForSelectedRow];
    if (selectedPath && selectedPath.section == section & selectedPath.row == rowIndex) return;
    if (tableView.numberOfSections <= section ||
        [tableView numberOfRowsInSection: section] <= rowIndex) return;
    
    CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
    cellRect = CGRectOffset(cellRect, -tableView.contentOffset.x, -tableView.contentOffset.y);
    int searchBarHeight = [self.searchDisplayController isActive] ? self.searchBar.frame.size.height : 0;
    int scrollPosition = UITableViewScrollPositionNone;
    if (cellRect.origin.y < tableView.frame.origin.y + self.searchBar.frame.size.height) {
        scrollPosition = UITableViewScrollPositionTop;
    }
    else if (cellRect.origin.y+cellRect.size.height > tableView.frame.origin.y+tableView.frame.size.height-searchBarHeight) {
        scrollPosition = UITableViewScrollPositionBottom;
    }
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:scrollPosition];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void) notesLoaded: (NSNotification*) notification {
    int numNotesReturned = 0;
    NSNumber* num = [notification.userInfo objectForKey:NUM_NOTES_RETURNED];
    if (num != nil) {
        numNotesReturned = [num intValue];
    }
    NSLog(@"Table view notified of %d notes loaded.", numNotesReturned);

    UITableView* tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableView reloadData];
    });
}

- (void) updateNotes {
    [[MarsImageNotebook instance] reloadNotes];
    UITableView* tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
    [tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void) imageSelected:(NSNotification *) notification {
    int index = 0;
    NSNumber* num = [notification.userInfo valueForKey:IMAGE_INDEX];
    if (num != nil) {
        index = [num intValue];
    }
    UIViewController* sender = [notification.userInfo valueForKey:SENDER];
    if (sender != self) {
        [self selectAndScrollToRow:index];
    }
}

- (IBAction) activateSearchBar {
    [_searchBar becomeFirstResponder];
}

- (IBAction) togglePullDownMenu {
    [_menu animateDropDown];
}

- (void) defaultsChanged:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *mission = [prefs stringForKey:MISSION];
    if (! [[MarsImageNotebook instance].missionName isEqualToString:mission]) {
        [MarsImageNotebook instance].missionName = mission;
        [_titleButton setTitle:mission forState:UIControlStateNormal];
        [self updateNotes];
    }
}

- (void) enteredForegroundAfterLongSleep:(id)sender {
    [self updateNotes];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [MarsImageNotebook instance].sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSNumber* sol = [[MarsImageNotebook instance].sols objectAtIndex:section];
    NSArray* imagesForSol = [[MarsImageNotebook instance].notes objectForKey:sol];
    return imagesForSol.count;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    return [[MarsImageNotebook instance].mission sectionTitle:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"SearchResultTableCellView" bundle:nil] forCellReuseIdentifier:SEARCH_CELL];
    
    NSString* cellId = (tableView == self.tableView) ? IMAGE_CELL : SEARCH_CELL;
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[FixedWidthImageTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    
    // Configure the cell...
//    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
//    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0];

    if ([MarsImageNotebook instance].sols.count <= indexPath.section) return nil;
    
    NSNumber* sol = [[MarsImageNotebook instance].sols objectAtIndex:indexPath.section];
    NSArray* imagesForSol = [[MarsImageNotebook instance].notes objectForKey:sol];
    EDAMNote* note = [imagesForSol objectAtIndex:indexPath.row];
    id<MarsRover> mission = [MarsImageNotebook instance].mission;
    [cell.textLabel setText:[mission labelText:note]];
    [cell.detailTextLabel setText:[mission detailLabelText:note]];
    
    EDAMResource* resource = [note.resources objectAtIndex:0];
    if (resource) {
        NSString* resGUID = resource.guid;
        NSString* thumbnailUrl = [NSString stringWithFormat:@"%@thm/res/%@?size=50", Evernote.instance.user.webApiUrlPrefix, resGUID];
        [cell.imageView setImageWithURL:[NSURL URLWithString:thumbnailUrl] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    }
    
    //try to load more images if we are at the last cell in the table
    int sectionCount = [MarsImageNotebook instance].sections.count;
    int imageCount = imagesForSol.count;
    if ([MarsImageNotebook instance].sections.count > 0 &&
        sectionCount - 1 == [indexPath section] && imageCount - 1 == [indexPath row]) {
        [[MarsImageNotebook instance] loadMoreNotes:[MarsImageNotebook instance].notesArray.count withTotal:15];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MarsSidePanelController* sidePanel = (MarsSidePanelController*)self.viewDeckController;
    int section = indexPath.section;
    int row = indexPath.row;
    int imageIndex = 0;
    for (int i = 0; i < section; i++) {
        NSNumber* sol = [[MarsImageNotebook instance].sols objectAtIndex:i];
        imageIndex += ((NSArray*)[[MarsImageNotebook instance].notes objectForKey:sol]).count;
    }
    imageIndex += row;
    [sidePanel imageSelected: imageIndex from:self];
}

#pragma mark UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [MarsImageNotebook instance].searchWords = searchBar.text;
    [[MarsImageNotebook instance] reloadNotes];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if ([MarsImageNotebook instance].searchWords) {
        [MarsImageNotebook instance].searchWords = nil;
        [[MarsImageNotebook instance] reloadNotes];
    }
}

#pragma mark UISearchDisplayDelegate
- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

@end
