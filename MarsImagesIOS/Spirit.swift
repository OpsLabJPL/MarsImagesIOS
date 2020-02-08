//
//  Spirit.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class Spirit: MER {
    
    override init() {
        super.init()
        var comps = DateComponents()
        comps.day=3
        comps.month=1
        comps.year=2004
        comps.hour=13
        comps.minute=36
        comps.second=15
        comps.timeZone = TimeZone(abbreviation: "UTC")
        self.epoch = Calendar.current.date(from: comps)
    }
    
    override func urlPrefix() -> String {
        return "https://mars.nasa.gov/mer-raw-images/spirit"
    }
}
