//
//  MarsPhoto.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import MWPhotoBrowser
import SDWebImage

class MarsPhoto: MWPhoto {
    
    var url:URL
    var imageset:Imageset
    var indexInImageset:Int
    var isLoading = false
    
    weak var leftImage:UIImage?
    weak var rightImage:UIImage?
    var leftAndRight:(String,String)?
    
    
    init (url:URL, imageset: Imageset, indexInImageset: Int) {
        self.url = url
        self.imageset = imageset
        self.indexInImageset = indexInImageset
        super.init(url:url)
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    init (_ imageset: Imageset, leftAndRight:(String,String)) {
        self.imageset = imageset
        self.leftAndRight = leftAndRight
        self.url = URL(string:leftAndRight.0)!
        self.indexInImageset = 0
        super.init()
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    func downloadImage(_ url:URL, _ setImageFunc:@escaping (_ image:UIImage?)->()) {
        let manager = SDWebImageManager.shared()!

        manager.downloadImage(with: url, options: [.allowInvalidSSLCertificates],
                              progress:  { (receivedSize, expectedSize) -> Void in
                                if expectedSize > 0 {
                                    let progress = Float(receivedSize)/Float(expectedSize)
                                    let dict:[String:Any] = ["progress": progress, "photo": self]
                                    NotificationCenter.default.post(name: .mwphotoProgressNotification, object: dict)
                                }
        },
                              completed: { (image, error, cacheType, finished, imageURL) -> Void in
                                if let error = error {
                                    print("Error: \(url) \(error)")
                                    return
                                }
                                setImageFunc(image)
                                if let leftImage = self.leftImage, let rightImage = self.rightImage {
                                    self.underlyingImage = ImageUtility.anaglyph(left: leftImage, right:rightImage)
                                    self.decompressImageAndFinishLoading()
                                }
        })
    }
    
    override func performLoadUnderlyingImageAndNotify() {
        isLoading = true
        guard (leftAndRight != nil) else {
            super.performLoadUnderlyingImageAndNotify()
            return
        }
        
        let leftUrl = leftAndRight!.0
        downloadImage(URL(string:leftUrl)!, { image in
            self.leftImage = image
        })
        let rightUrl = leftAndRight!.1
        downloadImage(URL(string:rightUrl)!, { image in
            self.rightImage = image
        })
    }

    func decompressImageAndFinishLoading() {
        if let image = self.underlyingImage {
            DispatchQueue.global().async {
                self.underlyingImage = UIImage.decodedImage(with: image)
                DispatchQueue.main.async {
                    self.imageLoadComplete()
                }
            }
        }
        imageLoadComplete()
    }

    func imageLoadComplete() {
        isLoading = false
        NotificationCenter.default.post(name: .mwphotoLoadingDidEndNotification, object: self)
    }
}

extension Notification.Name {
    static let mwphotoLoadingDidEndNotification = Notification.Name(MWPHOTO_LOADING_DID_END_NOTIFICATION)
    static let mwphotoProgressNotification = Notification.Name(MWPHOTO_PROGRESS_NOTIFICATION)
}
