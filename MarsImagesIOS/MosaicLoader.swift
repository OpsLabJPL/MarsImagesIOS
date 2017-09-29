//
//  MosaicLoader.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 9/17/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SceneKit

class MosaicLoader {
    
    var rmc:(Int,Int)
    var catalog:MarsImageCatalog
    var photosInScene = [String:MarsPhoto]()
    var photoQuads = [String:ImageQuad]()
    var qLL = Quaternion()
    var scene:SCNScene
    
    init(rmc:(Int,Int), catalog:MarsImageCatalog, scene:SCNScene) {
        self.rmc = rmc
        self.catalog = catalog
        self.scene = scene
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)

        catalog.localLevelQuaternion(rmc, completionHandler: { quaternion in
            self.qLL = quaternion
            self.addImagesToScene()
        })
    }
    
    func addImagesToScene() {
        catalog.searchWords = String(format:"%06d-%06d", rmc.0, rmc.1)
        catalog.reload()
    }
    
    @objc func imagesetsLoaded(notification: Notification) {
        let numLoaded = notification.userInfo?[numImagesetsReturnedKey] as? Int
        guard numLoaded != nil else {
            print("end imageset loading notification did not contain expected number of results.")
            return
        }
        if numLoaded! > 0 {
            //not done loading imagesets, request to load remaining
            DispatchQueue.main.async { //TODO: should this be on main? here to prevent deadlock on download queue
                self.catalog.loadNextPage()
            }
        } else {
            //all done loading imagesets, add them all to the scene
            binImagesByPointing(catalog.marsphotos)
            var mosaicCount = 0
            for (title, photo) in photosInScene {
                if let model = photo.modelJson {
                    mosaicCount += 1
                    let imageId = photo.imageId()
                    photoQuads[title] = ImageQuad(model: CameraModelUtils.model(model), qLL: qLL, imageId: imageId)
                    scene.rootNode.addChildNode(photoQuads[title]!.node)
                }
            }
        }
    }
    
    func binImagesByPointing(_ imagesForRMC:[MarsPhoto]) {
        for prospectiveImage in imagesForRMC.reversed() {
            //filter out any images that aren't on the mast i.e. mosaic-able.
            if !prospectiveImage.isIncludedInMosaic {
                continue
            }
            let angleThreshold:Double = prospectiveImage.fieldOfView()/10.0 //less overlap than ~5 degrees for Mastcam is problem for memory: see 42-852 looking south for example
            var tooCloseToAnotherImage = false
            for (_, image) in photosInScene {
                if image.angularDistance(otherImage: prospectiveImage) < angleThreshold &&
                    epsilonEquals(image.fieldOfView(), prospectiveImage.fieldOfView()) {
                    tooCloseToAnotherImage = true
                    break
                }
            }
            if (!tooCloseToAnotherImage) {
                photosInScene[prospectiveImage.imageset.title] = prospectiveImage
            }

        }
    }

}
