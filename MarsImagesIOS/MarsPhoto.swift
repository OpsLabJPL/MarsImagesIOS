//
//  MarsPhoto.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import MWPhotoBrowser

class MarsPhoto: MWPhoto {
    
    var url:URL
    
    override init (url:URL) {
        self.url = url
        super.init(url:url)
    }
    
}
