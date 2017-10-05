//
//  MarsImageCatalog.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import ReachabilitySwift

let numImagesetsReturnedKey = "numImagesetsReturnedKey"

extension Notification.Name {
    static let beginImagesetLoading = Notification.Name("BeginImagesetLoading")
    static let endImagesetLoading = Notification.Name("EndImagesetLoading")
    static let locationsLoaded = Notification.Name("LocationsLoaded")
    static let namedLocationsLoaded = Notification.Name("NamedLocationsLoaded")
}

protocol MarsImageCatalog {

    func reload()
    
    func hasMoreImages() -> Bool
    
    func loadNextPage()
    
    var mission:String { get set }
    
    var searchWords:String { get set }
    
    var imagesetCount:Int { get }
    
    var imagesets:[Imageset] { get }
    
    var marsphotos:[MarsPhoto] { get }
    
    var imagesetsForSol:[Int:[Imageset]] { get }
    
    var sols:[Int] { get }
    
    var solIndices:[Int:Int] { get }
    
    var imagesetCountsBySol:[Int:Int] { get }
    
    var reachability:Reachability { get }
    
    func imageName(imageset: Imageset, imageIndexInSet: Int) -> String
    
    func getImagesetCount(imageset: Imageset) -> Int
    
    func changeToImage(imagesetIndex: Int, imageIndexInSet: Int)
    
    func changeToAnaglyph(leftAndRight: (Int,Int), imageIndex: Int)
    
    func stereoForImages(imagesetIndex: Int) -> (Int,Int)?
    
    func getNearestRMC() -> (Int,Int)?
    
    func getNextRMC(rmc:(Int,Int)) -> (Int,Int)?

    func getPreviousRMC(rmc:(Int,Int)) -> (Int,Int)?
    
    func getLocations() -> [(Int,Int)]?
    
    func getNamedLocations() -> [String:(Int,Int)]?
    
    func reloadLocations()
    
    func localLevelQuaternion(_ rmc:(Int, Int), completionHandler:@escaping (Quaternion)->(Void))

}

class Imageset: Equatable {
    
    var mission:Mission
    var title:String
    var rowTitle:String
    var subtitle:String
    var thumbnailUrl:String?
    var sol:Int?
    
    init (title:String) {
        self.title = title
        self.mission = Mission.currentMission()
        self.rowTitle = mission.rowTitle(title)
        self.subtitle = mission.subtitle(title)
        self.sol = mission.sol(title)
    }
    
    static func ==(lhs: Imageset, rhs: Imageset) -> Bool {
        return lhs.title == rhs.title
    }
}
