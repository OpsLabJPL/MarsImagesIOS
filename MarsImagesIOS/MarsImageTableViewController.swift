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
import Reachability

class MarsImageTableViewController: UITableViewController {
    
    let imageCell = "ImageCell"
    let dropdownMenuWidth = 140
    let dropdownMenuRowHeight = 44

    var catalogs:[String:MarsImageCatalog] = (UIApplication.shared.delegate as! AppDelegate).catalogs
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    let aRefreshControl = UIRefreshControl()
    var navBarMenu:MKDropdownMenu?
    var internetStatusUnreachable: MessageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBarMenu = MKDropdownMenu(frame: CGRect(x:0,y:0,width:dropdownMenuWidth,height:dropdownMenuRowHeight))
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
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = aRefreshControl
        } else {
            tableView.addSubview(aRefreshControl)
        }
        aRefreshControl.attributedTitle = NSAttributedString(string:"Downlinking images from Mars", attributes:nil)
        aRefreshControl.addTarget(self, action: #selector(refreshImages(_:)), for: .valueChanged)

        
        tableView.scrollsToTop = true
        searchController.searchResultsUpdater = self
        
        //don't dim the table view that we're presenting over
        searchController.dimsBackgroundDuringPresentation = false
        
        //Ensure that the search bar does not remain on the screen if the user navigates to another view controller while the UISearchController is active.
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        
        clearsSelectionOnViewWillAppear = false
        
        // listen to user defaults (such as mission) changed events
        NotificationCenter.default.addObserver(self, selector: #selector(missionChanged), name: .missionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSelected), name: .imageSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: Notification.Name("reachabilityChanged"), object: catalogs[Mission.currentMissionName()]!.reachability)

        internetStatusUnreachable = InternetReachabilityStatus.createStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func missionChanged() {
        catalogs[Mission.currentMissionName()]?.reload()
        navBarMenu?.reloadAllComponents()
    }
    
    @IBAction func refreshImages(_ sender: Any) {
        catalogs[Mission.currentMissionName()]!.reload()
        aRefreshControl.endRefreshing()
    }
    
    @objc func imagesetsLoaded(notification: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func imageSelected(notification: Notification) {
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
    
//    func updateImagesets() {
//        catalog?.reload()
//        tableView.reloadData()
////        [self.refreshControl endRefreshing]; TODO UIRefreshControl
//    }
    
    func selectAndScrollToRow(imageIndex: Int) {
        guard imageIndex >= 0 || imageIndex < catalogs[Mission.currentMissionName()]!.imagesetCount else {
            return
        }
        let imageset:Imageset = catalogs[Mission.currentMissionName()]!.imagesets[imageIndex]
        let sol = Mission.currentMission().sol(imageset.title)
        let section = catalogs[Mission.currentMissionName()]!.solIndices[sol]!
        var rowIndex = 0;
        let imagesets = catalogs[Mission.currentMissionName()]!.imagesetsForSol[sol]!
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
        var scrollPosition = UITableView.ScrollPosition.none
        let height1 = cellRect.origin.y+cellRect.size.height
        let height2 = tableView.frame.origin.y+tableView.frame.size.height-searchBarHeight
        if cellRect.origin.y < tableView.frame.origin.y + searchBarHeight {
            scrollPosition = UITableView.ScrollPosition.top
        }
        else if height1 > height2 {
            scrollPosition = UITableView.ScrollPosition.bottom
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
    }
    
    ///MARK UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return catalogs[Mission.currentMissionName()]!.sols.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < catalogs[Mission.currentMissionName()]!.sols.count {
            let sol = catalogs[Mission.currentMissionName()]!.sols[section]
            if let imagesetsForSol = catalogs[Mission.currentMissionName()]!.imagesetsForSol[sol] {
                return imagesetsForSol.count
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < catalogs[Mission.currentMissionName()]!.sols.count {
            let sol = catalogs[Mission.currentMissionName()]!.sols[section]
            return Mission.currentMission().solAndDate(sol: sol)
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .darkGray
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .white
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < catalogs[Mission.currentMissionName()]!.sols.count else {
            return tableView.dequeueReusableCell(withIdentifier: imageCell)!
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: imageCell)!

        let sol = catalogs[Mission.currentMissionName()]!.sols[indexPath.section]
        if let imagesetsForSol = catalogs[Mission.currentMissionName()]!.imagesetsForSol[sol] {
            loadAnotherPageIfAtEnd(indexPath, imagesets: imagesetsForSol)
        
            let imageset = imagesetsForSol[indexPath.row]
            cell.textLabel?.text = imageset.rowTitle
            cell.detailTextLabel?.text = imageset.subtitle
        
            if let thumbnailUrl = imageset.thumbnailUrl {
                cell.imageView?.sd_setImage(with: URL(string:thumbnailUrl), placeholderImage: UIImage.init(named: "placeholder"))
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        var imageIndex = 0
        for i in 0..<section {
            let sol = catalogs[Mission.currentMissionName()]!.sols[i]
            imageIndex += catalogs[Mission.currentMissionName()]!.imagesetCountsBySol[sol]!
        }
        imageIndex += row;
        let dict:[String:Any] = [ Constants.imageIndexKey: imageIndex, Constants.senderKey: self ]
        NotificationCenter.default.post(name: .imageSelected, object: nil, userInfo: dict)
    }
    
    func loadAnotherPageIfAtEnd(_ indexPath:IndexPath, imagesets:[Imageset]) {
        //check for last row in last section & if so then load more imagesets
        //try to load more images if we are at the last cell in the table
        let sectionCount = catalogs[Mission.currentMissionName()]!.imagesetCountsBySol.count
        let imageCount = imagesets.count
        let lastSection = sectionCount - 1
        let lastImageset = imageCount - 1
        if catalogs[Mission.currentMissionName()]!.hasMoreImages() &&
            sectionCount > 0 &&
            lastSection == indexPath.section && lastImageset == indexPath.row {
            catalogs[Mission.currentMissionName()]!.loadNextPage()
        }
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        var statusConfig = SwiftMessages.defaultConfig
        statusConfig.duration = .forever
        statusConfig.presentationContext = .window(windowLevel: UIWindow.Level(rawValue: UIWindow.Level.statusBar.rawValue))
        
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
        catalogs[Mission.currentMissionName()]!.searchWords = searchText
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
            NotificationCenter.default.post(Notification(name: .missionChanged))
        }
        dropdownMenu.closeAllComponents(animated: true)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, widthForComponent component: Int) -> CGFloat {
        return CGFloat(dropdownMenuWidth)
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
    static let missionChanged = Notification.Name("missionChanged")
}
