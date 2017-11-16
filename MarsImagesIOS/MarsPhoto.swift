//
//  MarsPhoto.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import POWImageGallery
import SDWebImage
import SwiftyJSON

class MarsPhoto: ImageCreator {
    
    var imageset:Imageset
    var indexInImageset:Int
    var sourceUrl:String
    var modelJson:JSON?
    var caption:String
    
    var leftImage:UIImage?
    var rightImage:UIImage?
    var leftAndRight:(String,String)?
    var isIncludedInMosaic:Bool {
        return imageset.title.range(of:"Navcam") != nil
            || imageset.title.range(of:"Mastcam Left") != nil
            || imageset.title.range(of:"Pancam") != nil
    }
    
    required public init (url:URL, imageset: Imageset, indexInImageset: Int, sourceUrl:String, modelJsonString:String?) {
        self.imageset = imageset
        self.indexInImageset = indexInImageset
        self.sourceUrl = sourceUrl
        if let model = modelJsonString {
            modelJson = JSON(parseJSON:model)
        }
        self.caption = Mission.currentMission().caption(self.imageset.title)
        super.init(url:url, delegate:nil)
    }
    
    init (_ imageset: Imageset, leftAndRight:(String,String)) {
        self.imageset = imageset
        self.leftAndRight = leftAndRight
        self.sourceUrl = ""
        self.indexInImageset = 0
        self.caption = Mission.currentMission().caption(self.imageset.title)
        super.init(url:URL(string:leftAndRight.0)!, delegate:nil)
    }
    
    override open func requestImage() {
        guard (leftAndRight != nil) else {
            super.requestImage()
            return
        }

        if loadInProgress {
            return
        }
        loadInProgress = true

        let leftUrl = URL(string:leftAndRight!.0)
        SDWebImageManager.shared().loadImage(with: leftUrl, options: .refreshCached,
                                             progress:  { (receivedSize, expectedSize, targetUrl) -> Void in
                                                self.delegate?.progress?(receivedSize:receivedSize, expectedSize:expectedSize)
        },
                                             completed: { (image, data, error, cacheType, finished, imageURL) -> Void in
                                                if let image = image {
                                                    self.leftImage = image
                                                    self.processImage()
                                                } else {
                                                    self.delegate?.failure()
                                                }
        })
        let rightUrl = URL(string:leftAndRight!.1)
        SDWebImageManager.shared().loadImage(with: rightUrl, options: .refreshCached,
                                             progress:  { (receivedSize, expectedSize, targetUrl) -> Void in
                                                self.delegate?.progress?(receivedSize:receivedSize, expectedSize:expectedSize)
        },
                                             completed: { (image, data, error, cacheType, finished, imageURL) -> Void in
                                                if let image = image {
                                                    self.rightImage = image
                                                    self.processImage()
                                                } else {
                                                    self.delegate?.failure()
                                                }
        })
    }
    
    func processImage() {
        if let leftImage = self.leftImage, let rightImage = self.rightImage {
            let anaglyphImage = ImageUtility.anaglyph(left: leftImage, right:rightImage)
            self.delegate?.finished(image:anaglyphImage)
            self.leftImage = nil
            self.rightImage = nil
            self.loadInProgress = false
        }
    }
    
    func fieldOfView() -> Double {
        let imageId = Mission.imageId(url: sourceUrl)
        let cameraId = Mission.currentMission().getCameraId(imageId: imageId)
        return Mission.currentMission().getCameraFOV(cameraId: cameraId) 
    }
    
    func imageId() -> String {
        return Mission.imageId(url: sourceUrl)
    }
    
    func angularDistance(otherImage:MarsPhoto) -> Double {
        guard modelJson != nil && otherImage.modelJson != nil else {
            return 0.0
        }
        
        let v1 = CameraModelUtils.pointingVector(self.modelJson!)
        let v2 = CameraModelUtils.pointingVector(otherImage.modelJson!)
        let dotProduct = dot(v1,v2)
        return acos(dotProduct)
    }
}
