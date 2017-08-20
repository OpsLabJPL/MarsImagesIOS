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
    var imageset:Imageset
    var isLoading = false
    
    var leftImage:UIImage?
    var rightImage:UIImage?
    var leftAndRight:[URL]?
    
    
    init (url:URL, imageset: Imageset) {
        self.url = url
        self.imageset = imageset
        super.init(url:url)
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    override func performLoadUnderlyingImageAndNotify() {
        isLoading = true
        //TODO do the left and right thing
        super.performLoadUnderlyingImageAndNotify()
    }
    
    func imageLoadComplete() {
        isLoading = false
        DispatchQueue.global().async {
            NotificationCenter.default.post(name: .mwphotoLoadingDidEndNotification, object: self)
        }
    }
}

extension Notification.Name {
    static let mwphotoLoadingDidEndNotification = Notification.Name(MWPHOTO_LOADING_DID_END_NOTIFICATION)
}
