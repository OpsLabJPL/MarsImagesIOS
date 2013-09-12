//
//  SearchTableViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 11/30/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "SearchTableViewController.h"
#import "Search.h"
#import "MarsNotebook.h"

@interface SearchTableViewController ()

@end

@implementation SearchTableViewController

@synthesize searchString;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - device rotation support

- (NSUInteger) supportedInterfaceOrientationsForWindow {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    self.tableView.allowsSelection = NO;
    self.tableView.scrollEnabled = NO;
}

- (void)updateSearchString:(NSString*)aSearchString {
    searchString = nil;
    searchString = [[NSString alloc]initWithString:aSearchString];
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
    searchBar.text=@"";
    [self updateSearchString:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
    [self updateSearchString:searchBar.text];
    [MarsNotebook instance].searchWords = searchString;
    [[Search instance] updateSearchTerms: searchString];
    if (self.splitViewController) {
        UIViewController *vc = [self.splitViewController.viewControllers objectAtIndex:0];
        [vc viewWillAppear:YES]; //trigger table refresh
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[Search instance] filterSearchText:searchString] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"searchCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    NSString* searchOption = [[[Search instance] filterSearchText:searchString]objectAtIndex:indexPath.row];
    cell.textLabel.text = searchOption;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* selectedSearch = [[[Search instance]searches]objectAtIndex:indexPath.row];
    UISearchBar* searchBar = (UISearchBar*)self.tableView.tableHeaderView;
    searchBar.text = selectedSearch;
    [self searchBarSearchButtonClicked:searchBar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

@end
