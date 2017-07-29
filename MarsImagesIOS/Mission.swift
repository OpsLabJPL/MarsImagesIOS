//
//  Mission.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class Mission {
    static let names = [ OPPORTUNITY, SPIRIT, CURIOSITY ]
    static let missionKey = "mission"
    static let OPPORTUNITY = "OPPORTUNITY"
    static let SPIRIT = "SPIRIT"
    static let CURIOSITY = "CURIOSITY"
    
    static let missions:[String:Mission] = [OPPORTUNITY: Opportunity(), SPIRIT: Spirit(), CURIOSITY: Curiosity()]
    
    static func currentMission() -> Mission {
        return missions[currentMissionName()]!
    }
    
    static func currentMissionName() -> String {
        let userDefaults = UserDefaults.standard
        if userDefaults.value(forKey: missionKey) == nil {
            userDefaults.set(OPPORTUNITY, forKey: missionKey)
            userDefaults.synchronize()
        }
        return userDefaults.value(forKey: missionKey) as! String
    }
    
    func rowTitle(_ title: String) -> String {
        return title
    }
    
    func subtitle(_ title: String) -> String {
        let marstime = tokenize(title).marsLocalTime
        return "\(marstime) LST"
    }
    
    func tokenize(_ title: String) -> Title {
        return Title()
    }
    
    func getSortableImageFilename(url: String) -> String {
        return url
    }
}

class Title {
    var sol = 0
    var imageSetID = ""
    var instrumentName = ""
    var marsLocalTime = ""
    var siteIndex = 0
    var driveIndex = 0
}
