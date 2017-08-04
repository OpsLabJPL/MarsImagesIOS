//
//  ViewController.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import SDWebImage
import MKDropdownMenu
import SwiftMessages
import ReachabilitySwift

class MarsImageTableViewController: UITableViewController {
    
    let imageCell = "ImageCell"
    let dropdowMenuWidth = 140
    let dropdownMenuRowHeight = 44

    var catalog:MarsImageCatalog?
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    var navBarMenu:MKDropdownMenu?
    var internetStatusUnreachable: MessageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBarMenu = MKDropdownMenu(frame: CGRect(x:0,y:0,width:dropdowMenuWidth,height:dropdownMenuRowHeight))
        navBarMenu?.dataSource = self
        navBarMenu?.delegate = self
        navBarMenu?.backgroundDimmingOpacity = -0.67
        navBarMenu?.adjustsContentOffset = true
        navBarMenu?.adjustsContentInset = true
        navBarMenu?.dropdownShowsTopRowSeparator = false
        navBarMenu?.dropdownBouncesScroll = false
        navBarMenu?.dropdownShowsTopRowSeparator = true
        navBarMenu?.dropdownShowsBottomRowSeparator = false
        navBarMenu?.rowSeparatorColor = .gray
        navBarMenu?.rowTextAlignment = .left
        navBarMenu?.dropdownRoundedCorners = .allCorners
        navBarMenu?.useFullScreenWidth = false
        navigationItem.titleView = navBarMenu
        
        tableView.scrollsToTop = true
        searchController.searchResultsUpdater = self
        
        //don't dim the table view that we're presenting over
        searchController.dimsBackgroundDuringPresentation = false
        
        //Ensure that the search bar does not remain on the screen if the user navigates to another view controller while the UISearchController is active.
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        
        //TODO add the UIRefreshControl or equivalent
        
        clearsSelectionOnViewWillAppear = false
        
        // listen to user defaults (such as mission) changed events
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: catalog?.reachability)

        internetStatusUnreachable = InternetReachabilityStatus.createStatus()
        
        catalog?.reload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func defaultsChanged() {
        let mission = Mission.currentMissionName()
        //TODO move this to Catalog
//    if (! [[MarsImageNotebook instance].missionName isEqualToString:mission]) {
//        [[MarsImageNotebook instance] reloadLocations];
//        [MarsImageNotebook instance].searchWords = nil;
//    }
        
        catalog?.mission = mission
        updateImagesets()
        navBarMenu?.reloadAllComponents()
    }
    
    func imagesetsLoaded(notification: Notification) {
        var numImagesetsReturned = 0
        let num = notification.userInfo?[numImagesetsReturnedKey]
        if (num != nil) {
            numImagesetsReturned = num as! Int
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func imageSelected(notification: Notification) {
        var index = 0;
        if let num = notification.userInfo?[Constants.imageIndexKey] as? Int {
            index = Int(num)
        }
        if let sender = notification.userInfo?[Constants.senderKey] as? NSObject {
            if sender != self {
                selectAndScrollToRow(imageIndex:index)
            }
        }
    }
    
    func updateImagesets() {
        catalog?.reload()
        tableView.reloadData()
//        [self.refreshControl endRefreshing]; TODO UIRefreshControl
    }
    
    func selectAndScrollToRow(imageIndex: Int) {
        guard imageIndex >= 0 || imageIndex < catalog!.imagesetCount else {
            return
        }
        let imageset:Imageset = catalog!.imagesets[imageIndex]
        let sol = Mission.currentMission().sol(imageset.title)
        let section = catalog!.solIndices[sol]!
        var rowIndex = 0;
        let imagesets = catalog!.imagesetsForSol[sol]!
        for iset in imagesets {
            if iset == imageset {
                break
            }
            rowIndex += 1;
        }
        if (rowIndex == imagesets.count) {
            return
        }
        
        // Get the cell rect and adjust it to consider scroll offset
        let indexPath = IndexPath(row: rowIndex, section: section)
        let selectedPath = tableView.indexPathForSelectedRow
        if selectedPath != nil && selectedPath!.section == section && selectedPath!.row == rowIndex {
            return
        }
        if tableView.numberOfSections <= section || tableView.numberOfRows(inSection: section) <= rowIndex {
            return
        }
        
        var cellRect = tableView.rectForRow(at: indexPath)
        cellRect = cellRect.offsetBy(dx: -tableView.contentOffset.x, dy: -tableView.contentOffset.y)
        let searchBarHeight = searchController.searchBar.frame.size.height
        var scrollPosition = UITableViewScrollPosition.none
        if cellRect.origin.y < tableView.frame.origin.y + searchBarHeight {
            scrollPosition = UITableViewScrollPosition.top
        }
        else if cellRect.origin.y+cellRect.size.height > tableView.frame.origin.y+tableView.frame.size.height-searchBarHeight {
            scrollPosition = UITableViewScrollPosition.bottom
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)


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
        return Mission.currentMission().solAndDate(sol: sol)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .darkGray
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .white
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let sol = catalog!.sols[indexPath.section]
        let imagesetsForSol = catalog!.imagesetsForSol[sol]!
        loadAnotherPageIfAtEnd(indexPath, imagesets: imagesetsForSol)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: imageCell)!
        
        let imageset = imagesetsForSol[indexPath.row]
        cell.textLabel?.text = imageset.rowTitle
        cell.detailTextLabel?.text = imageset.subtitle
        
        if let thumbnailUrl = imageset.thumbnailUrl {
            cell.imageView?.sd_setImage(with: URL(string:thumbnailUrl), placeholderImage: UIImage.init(named: "placeholder.png"))
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        var imageIndex = 0
        for i in 0..<section {
            let sol = catalog!.sols[i]
            imageIndex += catalog!.imagesetCountsBySol[sol]!
        }
        imageIndex += row;
        let dict:[String:Any] = [ Constants.imageIndexKey: imageIndex, Constants.senderKey: self ]
        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
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
    
    @objc func reachabilityChanged(_ note: Notification) {
        
        let reachability = note.object as! Reachability
        
        var statusConfig = SwiftMessages.defaultConfig
        statusConfig.duration = .forever
        statusConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        
        if let status = self.internetStatusUnreachable {
            if reachability.isReachable {
                SwiftMessages.hide()
            } else {
                SwiftMessages.show(config: statusConfig, view: status)
            }
        }
    }
}

extension MarsImageTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String) {
        catalog?.searchWords = searchText
        tableView.reloadData()
    }
}

class FixedWidthImageTableViewCell: UITableViewCell {
    open override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.bounds.size.height
        self.imageView?.frame = CGRect(x:0,y:0,width:height,height:height)
        self.textLabel?.frame = CGRect(x:50,y:2,width:500,height:20)
        self.detailTextLabel?.frame = CGRect(x:50,y:24,width:500,height:20)
    }
}

extension MarsImageTableViewController: MKDropdownMenuDataSource {
    func numberOfComponents(in dropdownMenu: MKDropdownMenu) -> Int {
        return 1
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, numberOfRowsInComponent component: Int) -> Int {
        return Mission.names.count
    }
}

extension MarsImageTableViewController: MKDropdownMenuDelegate {
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, didSelectRow row: Int, inComponent component: Int) {
        let newMissionName = Mission.names[row]
        if Mission.currentMissionName() != newMissionName {
            let userDefaults = UserDefaults.standard
            userDefaults.set(newMissionName, forKey: Mission.missionKey)
            userDefaults.synchronize()
        }
        dropdownMenu.closeAllComponents(animated: true)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, widthForComponent component: Int) -> CGFloat {
        return CGFloat(dropdowMenuWidth)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(dropdownMenuRowHeight)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, titleForComponent component: Int) -> String? {
        return Mission.currentMissionName()
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, titleForRow row: Int, forComponent component: Int) -> String? {
        return Mission.names[row]
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, backgroundColorForRow row: Int, forComponent component: Int) -> UIColor? {
        return UIColor.white
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, shouldUseFullRowWidthForComponent component: Int) -> Bool {
        return false
    }
}

extension Notification.Name {
    static let imageSelected = Notification.Name("imageSelected")
}
