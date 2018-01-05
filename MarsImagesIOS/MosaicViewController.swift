    //
//  MosaicViewController.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 9/7/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import CoreMotion
import SceneKit

class MosaicViewController : UIViewController {
    
    var catalog:MarsImageCatalog?
    var mosaicLoader:MosaicLoader?
    @IBOutlet weak var scenekitView: SCNView!
    
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    private var previousTranslation = CGPoint.zero
    private var currentTranslationDelta = CGPoint.zero
    private var cumulativeRotationOffset = CGPoint.zero
    var startScale = 0.0
    var lastScale = 2.0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        scenekitView.backgroundColor = UIColor.black
        scenekitView.allowsCameraControl = false
        setupScene()
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(gestureRecognize:)))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(gestureRecognize:)))
        scenekitView.addGestureRecognizer(panRecognizer)
        scenekitView.addGestureRecognizer(pinchRecognizer)
        scenekitView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let loader = mosaicLoader {
            NotificationCenter.default.removeObserver(loader, name: .endImagesetLoading, object: nil)
        }
        super.viewWillDisappear(animated)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    @IBAction func previousLocationSelected(_ sender: Any) {
        if let currentRMC = mosaicLoader?.rmc {
            if let previousRMC = catalog!.getPreviousRMC(rmc: currentRMC) {
                mosaicLoader?.setRMC(previousRMC)
            }
        }
    }
    
    @IBAction func nextLocationSelected(_ sender: Any) {
        if let currentRMC = mosaicLoader?.rmc {
            if let nextRMC = catalog!.getNextRMC(rmc: currentRMC) {
                mosaicLoader?.setRMC(nextRMC)
            }
        }
    }
    
    func setupScene() {
        scnScene = SCNScene(named: "mosaic.scnassets/mosaic.scn")
        let screenWidthPixels = Double(view.bounds.width * view.contentScaleFactor) //convert width from points to pixels
        scenekitView.scene = scnScene
        cameraNode = scnScene.rootNode.childNode(withName: "camera", recursively: true)!
        if let rmc = catalog!.getNearestRMC() {
            mosaicLoader = MosaicLoader(rmc:rmc, catalog:catalog!, scene: scnScene, view: scenekitView, camera: cameraNode!.camera!, screenWidthPixels: screenWidthPixels)
        }
    }

    
    @objc func pinchGesture(gestureRecognize: UIPinchGestureRecognizer) {
        
        if gestureRecognize.numberOfTouches == 2 {
            
            let zoom = Double(gestureRecognize.scale)
            if (gestureRecognize.state == UIGestureRecognizerState.began){
                startScale = lastScale
            } else if (gestureRecognize.state == UIGestureRecognizerState.changed){
                let newScale = boundedZoom(zoom)
                let fov = Double(100/newScale)
                cameraNode.camera!.xFov = fov
                cameraNode.camera!.yFov = fov
                lastScale = boundedZoom(zoom)
            } else {
                lastScale = boundedZoom(zoom)
            }
        }
    }
    
    func boundedZoom(_ zoom: Double) -> Double {
        return min(max(startScale * zoom, 0.75), 16)
    }
    
    func getCameraFOV() -> Double {
        return cameraNode.camera!.xFov > 0 ? cameraNode.camera!.xFov : cameraNode.camera!.yFov
    }

    @objc func panGesture(gestureRecognize: UIPanGestureRecognizer) {
        
        switch gestureRecognize.state {
        case .began: previousTranslation = .zero
        case .changed:
            let currentTranslation = gestureRecognize.translation(in: scenekitView)
            currentTranslationDelta = CGPoint(x: currentTranslation.x - previousTranslation.x, y: currentTranslation.y - previousTranslation.y)
            previousTranslation = currentTranslation
        default:
            previousTranslation = .zero
            currentTranslationDelta = .zero
        }
        updateCameraOrientation()
    }
    
    //based on some nice work here: https://github.com/keithbhunter/PanoramicImageView/blob/master/PanoramicImageView.swift
    private func updateCameraOrientation() {
        let y = (currentTranslationDelta.x / CGFloat(lastScale) / scenekitView.bounds.size.width) * CGFloat.pi * 2
        let x = (currentTranslationDelta.y / CGFloat(lastScale) / scenekitView.bounds.size.height) * CGFloat.pi
        
        // Reset the delta. If we don't do this, the camera will continue to rotate if the user leaves their finger on the screen.
        currentTranslationDelta = .zero
        
        // If we are using core motion, combine the device motion data with the pan gesture data.
        // Else, just use the pan gesture data.
//        if let motion = deviceMotion {
//            cumulativeRotationOffset.x += x
//            cumulativeRotationOffset.y += y
//            cameraNode.orientation = rotate(motion.gaze(at: UIApplication.shared.statusBarOrientation), by: cumulativeRotationOffset)
//        } else {
            cameraNode.orientation = rotate(cameraNode.orientation, by: CGPoint(x: x, y: y))
//        }
    }
    
    // Quaternion math from: https://github.com/alfiehanssen/ThreeSixtyPlayer
    private func rotate(_ orientation: SCNQuaternion, by rotationOffset: CGPoint) -> SCNQuaternion {
        // Represent the orientation as a GLKQuaternion
        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        
        // Perform up and down rotations around *CAMERA* X axis (note the order of multiplication)
        let xMultiplier = GLKQuaternionMakeWithAngleAndAxis(Float(rotationOffset.x), 1, 0, 0)
        glQuaternion = GLKQuaternionMultiply(glQuaternion, xMultiplier)
        
        // Perform side to side rotations around *WORLD* Y axis (note the order of multiplication, different from above)
        let yMultiplier = GLKQuaternionMakeWithAngleAndAxis(Float(rotationOffset.y), 0, 1, 0)
        glQuaternion = GLKQuaternionMultiply(yMultiplier, glQuaternion)
        
        return SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
    }
}

extension MosaicViewController : SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        mosaicLoader?.updateOrRemoveImages(camera: cameraNode, renderer: renderer)
    }
}


// Extension from: https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
private extension CMDeviceMotion {
    
    func gaze(at orientation: UIInterfaceOrientation) -> SCNVector4 {
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
        let final: SCNVector4
        
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeRight:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float.pi / 2, 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)
            
        case .landscapeLeft:
            let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)
            
        case .portraitUpsideDown:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float.pi / 2, 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)
            
        case .unknown:
            fallthrough
            
        case .portrait:
            let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
        }
        
        return final
    }
    
}
