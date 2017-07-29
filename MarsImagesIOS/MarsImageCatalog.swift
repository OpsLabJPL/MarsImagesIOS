//
//  MarsImageCatalog.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

let numImagesetsReturnedKey = "numImagesetsReturnedKey"

extension Notification.Name {
    static let beginImagesetLoading = Notification.Name("BeginImagesetLoading")
    static let endImagesetLoading = Notification.Name("EndImagesetLoading")
}

protocol MarsImageCatalog {

    func reload()
    
    func loadNextPage()
    
    var imagesetCount:Int { get }
    
    var imagesets:[Imageset] { get }
    
    var imagesetsForSol:[Int:[Imageset]] { get }
    
    var sols:[Int] { get }
    
    var imagesetCountsBySol:[Int:Int] { get }
}

class Imageset {
    
    var mission:Mission
    var title:String
    var rowTitle:String
    var subtitle:String
    var thumbnailUrl:String?
    
    init (title:String) {
        self.title = title
        self.mission = Mission.currentMission()
        self.rowTitle = mission.rowTitle(title)
        self.subtitle = mission.subtitle(title)
    }
    
}
