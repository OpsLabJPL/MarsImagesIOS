//
//  MosaicViewController.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 9/7/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import SceneKit

class MosaicViewController : UIViewController {
    
    var scenekitView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scenekitView = self.view as! SCNView
        scenekitView.backgroundColor = UIColor.black
        scenekitView.allowsCameraControl = true
        setupScene()
        setupCamera()
        addBox()
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
    
    func setupScene() {
        scnScene = SCNScene()
        scenekitView.scene = scnScene
    }

    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func addBox() {
        let geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0,
                              chamferRadius: 0.0)
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = SCNVector3(x: 0, y: 0, z: -10)
        scnScene.rootNode.addChildNode(geometryNode)
    }
}
