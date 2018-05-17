//
//  Log.swift
//  MarsImages
//
//  Created by Mark Powell on 5/16/18.
//  Copyright © 2018 Mark Powell. All rights reserved.
//

import Foundation
import Crashlytics
import Fabric

struct Log {
    static func initLog() {
        Fabric.with([ Crashlytics.self ])
    }
    
    static func logEvent(_ event: String) {
        Answers.logCustomEvent(withName: event, customAttributes: nil)
    }
    
    static func logView(_ view: String) {
        Answers.logContentView(withName: view, contentType: nil, contentId: nil, customAttributes: nil)
    }
}
