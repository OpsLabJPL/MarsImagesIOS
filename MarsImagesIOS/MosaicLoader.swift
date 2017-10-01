//
//  MosaicLoader.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 9/17/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SceneKit
import SDWebImage

class MosaicLoader {
    
    var rmc:(Int,Int)
    var catalog:MarsImageCatalog
    var imagesInScene = [String:MarsPhoto]()
    var imageQuads = [String:ImageQuad]()
    var imageTextures = [String:UIImage]()
    var qLL = Quaternion()
    var scene:SCNScene
    var view:SCNView
    var camera:SCNCamera
    
    init(rmc:(Int,Int), catalog:MarsImageCatalog, scene:SCNScene, view: SCNView, camera: SCNCamera) {
        self.rmc = rmc
        self.catalog = catalog
        self.scene = scene
        self.view = view
        self.camera = camera
        NotificationCenter.default.addObserver(self, selector: #selector(imagesetsLoaded), name: .endImagesetLoading, object: nil)

        catalog.localLevelQuaternion(rmc, completionHandler: { quaternion in
            self.qLL = quaternion
            self.addImagesToScene()
        })
        
      SDImageCache.shared().maxMemoryCost = 128000
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
            for (title, photo) in imagesInScene {
                if let model = photo.modelJson {
                    mosaicCount += 1
                    let imageId = photo.imageId()
                    imageQuads[title] = ImageQuad(model: CameraModelUtils.model(model), qLL: qLL, imageId: imageId)
                    scene.rootNode.addChildNode(imageQuads[title]!.node)
                }
            }
        }
    }
    
    /* called from render loop update callback */
    func updateOrRemoveImages(camera: SCNNode, renderer: SCNSceneRenderer) {
        for (title, imageQuad) in imageQuads {

            let node = imageQuad.node

            // if the image is in the view, load/draw it
            
            if renderer.isNode(node, insideFrustumOf: camera) {
                
                //set triangle geometry and load or draw texture
                if node.geometry != imageQuad.triangleGeometry {
                    if let texture = imageTextures[title] {
                        print("Texture size: \(texture.size.width),\(texture.size.height)")
                        if node.geometry != imageQuad.triangleGeometry {
                            //add texture
                            if imageQuad.triangleGeometry.firstMaterial?.diffuse.contents as? UIImage != texture {
                                let textureMaterial = SCNMaterial()
                                textureMaterial.diffuse.contents = texture
                                imageQuad.triangleGeometry.firstMaterial = textureMaterial
                                imageQuad.outlineGeometry.firstMaterial?.diffuse.contents = UIColor.clear
                            }
                            node.geometry = imageQuad.triangleGeometry
                        }
                        
                        //recheck texture size to make sure it's optimal for display, else request a reload
                        let textureSize = computeBestTextureResolution(imageQuad)
                        if (textureSize != imageQuad.textureSize) {
                            loadImageAndTexture(title)
                        }
                    } else {
                        loadImageAndTexture(title)
                    }
                } else { //this is triangle geoemetry, but we should check that it has the latest texture
                    if let texture = imageTextures[title] {
                        if imageQuad.triangleGeometry.firstMaterial?.diffuse.contents as? UIImage != texture {
                            imageQuad.triangleGeometry.firstMaterial?.diffuse.contents = texture
                        }
                        //recheck texture size to make sure it's optimal for display, else request a reload
                        let textureSize = computeBestTextureResolution(imageQuad)
                        if (textureSize != imageQuad.textureSize) {
                            loadImageAndTexture(title)
                        }
                    }
                }
            }
            
            // if the image is out of view, delete the texture and don't draw it

            else {
                //set lines geometry
                if node.geometry != imageQuad.outlineGeometry {
                    imageQuad.outlineGeometry.firstMaterial?.diffuse.contents = ImageQuad.yellow
                    node.geometry = imageQuad.outlineGeometry
                    unloadImage(title)
                }
            }
        }
    }
    
    func loadImageAndTexture(_ title: String) {
        if let photo = imagesInScene[title] {
            if photo.underlyingImage == nil {
                if photo.isLoading == false {
                    photo.performLoadUnderlyingImageAndNotify()
                }
            }
             else {
                makeTexture(title, photo)
                //TODO this the old way: manage my own textures. Still need?
//            [photo unloadUnderlyingImage]; //after making texture, improves memory management quite significantly
            }
        }
    }
    
    func unloadImage(_ title: String) {
        if let photo = imagesInScene[title] {
            if photo.underlyingImage != nil {
                photo.unloadUnderlyingImage()
            }
            //TODO old way: delete my own managed texture. Still need?
        }
    }
    
    func deleteImages() {
        imagesInScene.removeAll()
        imageTextures.removeAll()
        imageQuads.removeAll()
    }
    
    func makeTexture(_ title: String, _ photo: MarsPhoto) {
        if let image = photo.underlyingImage {
            let quad = imageQuads[title]!
            quad.textureSize = computeBestTextureResolution(quad)
            imageTextures[title] = ImageUtility.image(image, scaledTo:CGSize(width:quad.textureSize, height:quad.textureSize))
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
            for (_, image) in imagesInScene {
                if image.angularDistance(otherImage: prospectiveImage) < angleThreshold &&
                    epsilonEquals(image.fieldOfView(), prospectiveImage.fieldOfView()) {
                    tooCloseToAnotherImage = true
                    break
                }
            }
            if (!tooCloseToAnotherImage) {
                imagesInScene[prospectiveImage.imageset.title] = prospectiveImage
            }
        }
    }

    func computeBestTextureResolution(_ imageQuad: ImageQuad) -> Int {
        let screenWidthPixels = Double(view.bounds.width * view.contentScaleFactor) //convert width from points to pixels
        let fov = camera.xFov == 0 ? camera.yFov : camera.xFov
        let viewportFovRadians = fov / 180.0 * Double.pi
        let cameraFovRadians = imageQuad.cameraFOVRadians()
        let idealPixelResolution = screenWidthPixels * cameraFovRadians / viewportFovRadians
        let bestTextureResolution = floorPowerOfTwo(idealPixelResolution)
//        print ("resolution: \(bestTextureResolution)")
        return bestTextureResolution > 1024  ? 1024 : bestTextureResolution
    }
}
