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
    
    static func currentMissionName() -> String {
        let userDefaults = UserDefaults.standard
        if userDefaults.value(forKey: missionKey) == nil {
            userDefaults.set(OPPORTUNITY, forKey: missionKey)
            userDefaults.synchronize()
        }
        return userDefaults.value(forKey: missionKey) as! String
    }
}
