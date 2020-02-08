//
//  Opportunity.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class Opportunity: MER {
    override init() {
        super.init()
        var comps = DateComponents()
        comps.day=24
        comps.month=1
        comps.year=2004
        comps.hour=15
        comps.minute=8
        comps.second=59
        comps.timeZone = TimeZone(abbreviation: "UTC")
        self.epoch = Calendar.current.date(from: comps)
    }
    
    override func urlPrefix() -> String {
        return "https://mars.nasa.gov/mer-raw-images"
    }
}
