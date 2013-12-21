//
//  MarsImageTableViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 12/12/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MarsImageTableViewController.h"
#import "Evernote.h"
#import "MarsImageNotebook.h"
#import "MarsRovers.h"
#import "MarsSidePanelController.h"
#import "UIImageView+WebCache.h"
#import "UIViewController+JASidePanel.h"

#define IMAGE_CELL @"ImageCell"

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
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    //TODO get this selector right
    [refreshControl addTarget:self action:@selector(updateNotes) forControlEvents:UIControlEventValueChanged];
    [refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Updating"]];
    self.refreshControl = refreshControl;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString* currentMission = [prefs stringForKey:@"mission"];
    self.title = currentMission;
    
    // Uncomment the following line to disable preservation of selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    //listen for preference changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredForegroundAfterLongSleep:) name:@"EnteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesLoaded:) name:END_NOTE_LOADING object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageSelected:) name:IMAGE_SELECTED object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
    MarsSidePanelController* sidePanel = (MarsSidePanelController*)self.sidePanelController;
    [self selectAndScrollToRow:sidePanel.imageIndex];
}

- (void) selectAndScrollToRow:(int)index {
    if (index < 0 || index > [self.tableView numberOfRowsInSection:0]-1) {
        return;
    }
    // Get the cell rect and adjust it to consider scroll offset
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    cellRect = CGRectOffset(cellRect, -self.tableView.contentOffset.x, -self.tableView.contentOffset.y);
    int scrollPosition = UITableViewScrollPositionNone;
    if (cellRect.origin.y < self.tableView.frame.origin.y) {
        scrollPosition = UITableViewScrollPositionTop;
    }
    else if (cellRect.origin.y+cellRect.size.height > self.tableView.frame.origin.y+self.tableView.frame.size.height) {
        scrollPosition = UITableViewScrollPositionBottom;
    }
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:scrollPosition];
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
    if (numNotesReturned > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void) updateNotes {
    [[MarsImageNotebook instance] reloadNotes];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void) imageSelected:(NSNotification *) notification {
    int index = 0;
    NSNumber* num = [notification.userInfo valueForKey:IMAGE_INDEX];
    if (num != nil) {
        index = [num intValue];
    }
    UIViewController* sender = [notification.userInfo valueForKey:SENDER];
    if (sender != self && index != [self.tableView indexPathForSelectedRow].row) {
        [self selectAndScrollToRow:index];
    }
}

- (void) defaultsChanged:(id)sender {
    //TODO
}

- (void) enteredForegroundAfterLongSleep:(id)sender {
    //TODO
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //TODO number of sections == number of sols?
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //TODO number of sections == number of sols?
    return [MarsImageNotebook instance].notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = IMAGE_CELL;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:IMAGE_CELL];
    }
    // Configure the cell...
    EDAMNote* note = [[MarsImageNotebook instance].notes objectAtIndex:indexPath.row];
    [cell.textLabel setText:note.title];
    
    EDAMResource* resource = [note.resources objectAtIndex:0];
    if (resource) {
        NSString* resGUID = resource.guid;
        NSString* thumbnailUrl = [NSString stringWithFormat:@"%@thm/res/%@?size=50", Evernote.instance.user.webApiUrlPrefix, resGUID];
        NSLog(@"thumbnailUrl: %@", thumbnailUrl);
        [cell.imageView setImageWithURL:[NSURL URLWithString:thumbnailUrl] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    }
    
    //try to load more images if we are at the last cell in the table
    int count = [MarsImageNotebook instance].notes.count;
    if (count - 1 == [indexPath row]) {
        [[MarsImageNotebook instance] loadMoreNotes:count withTotal:15];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MarsSidePanelController* sidePanel = (MarsSidePanelController*)self.sidePanelController;
    [sidePanel imageSelected: indexPath.row from:self];
}

@end
