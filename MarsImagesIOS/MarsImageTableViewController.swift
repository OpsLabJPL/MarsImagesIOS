//
//  ViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import SDWebImage

class MarsImageTableViewController: UITableViewController {

    
    let imageCell = "ImageCell"

    var catalog:MarsImageCatalog?

     @IBOutlet weak var refreshButton: UIBarButtonItem!
    let searchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.scrollsToTop = true
        searchController.searchResultsUpdater = self
        
        //don't dim the table view that we're presenting over
        searchController.dimsBackgroundDuringPresentation = false
        
        //Ensure that the search bar does not remain on the screen if the user navigates to another view controller while the UISearchController is active.
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        
        //TODO add the PSMenuItem for mission or equivalent
        
        //TODO add the UIRefreshControl or equivalent
        
        //TOOD add a mission title button in nav bar, or equivalent
        
        clearsSelectionOnViewWillAppear = false
        
        // listen to user defaults (such as mission) changed events
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func defaultsChanged() {
        let mission = Mission.currentMissionName()
        //TODO move this to Catalog
//    if (! [[MarsImageNotebook instance].missionName isEqualToString:mission]) {
//        [MarsImageNotebook instance].missionName = mission;
//        [[MarsImageNotebook instance] reloadLocations];
//        [MarsImageNotebook instance].searchWords = nil;
//    }
        
//        [_titleButton setTitle:mission forState:UIControlStateNormal]; TODO do this later
        
        updateImagesets()
    }
    
    func imagesetsLoaded(notification: Notification) {
        var numImagesetsReturned = 0;
        let num = notification.userInfo?[numImagesetsReturnedKey]
        if (num != nil) {
            numImagesetsReturned = num as! Int
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }

    }
    
    func updateImagesets() {
        catalog?.reload()
        tableView.reloadData()
//        [self.refreshControl endRefreshing]; TODO UIRefreshControl
    }
    
    ///MARK UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return catalog!.sols.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sol = catalog!.sols[section]
        let imagesetsForSol = catalog!.imagesetsForSol[sol]!
        return imagesetsForSol.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sol = catalog!.sols[section]

        //TODO customize this
        return "Sol \(sol)"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let sol = catalog!.sols[indexPath.section]
        let imagesetsForSol = catalog!.imagesetsForSol[sol]!
        loadAnotherPageIfAtEnd(indexPath, imagesets: imagesetsForSol)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: imageCell)!
        
        let imageset = imagesetsForSol[indexPath.row]
        cell.textLabel?.text = imageset.rowTitle
        cell.detailTextLabel?.text = imageset.subtitle
        
        //TODO do load thumbnail
        if let thumbnailUrl = imageset.thumbnailUrl {
            cell.imageView?.sd_setImage(with: URL(string:thumbnailUrl), placeholderImage: UIImage.init(named: "placeholder.png"))
//            [NSURL URLWithString:thumbnailUrl] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];

        }
        return cell
        
    }

    func loadAnotherPageIfAtEnd(_ indexPath:IndexPath, imagesets:[Imageset]) {
        //check for last row in last section & if so then load more imagesets
        //try to load more images if we are at the last cell in the table
        let sectionCount = catalog!.imagesetCountsBySol.count
        let imageCount = imagesets.count
        let lastSection = sectionCount - 1
        let lastImageset = imageCount - 1
        if sectionCount > 0 &&
            lastSection == indexPath.section && lastImageset == indexPath.row {
            catalog!.loadNextPage()
        }
    }
}

extension MarsImageTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        //TODO do this
        tableView.reloadData()
    }
}

extension UITableViewCell {
    open override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.bounds.size.height;
        self.imageView?.frame = CGRect(x:0,y:0,width:height,height:height)
        self.textLabel?.frame = CGRect(x:50,y:2,width:500,height:20);
        self.detailTextLabel?.frame = CGRect(x:50,y:24,width:500,height:20);
    }
}
