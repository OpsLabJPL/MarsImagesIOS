//
//  ImageQuad.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 9/26/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SceneKit

class ImageQuad {
    
    static let yellow = UIColor.yellow.withAlphaComponent(0.25)
    let triangleIndices:[Int32] = [0,1,2,3]
    
    let mast = Mission.currentMission().mastPosition()
    let xAxis = [1.0,0.0,0.0]
    let yAxis = [0.0,1.0,0.0]
    let zAxis = [0.0,0.0,1.0]
    
    var model:CameraModel
    var qLL:Quaternion
    var imageId:String
    
    var node = SCNNode()
    var cameraId:String
    var quadVertexSource = SCNGeometrySource()
    var triangleGeometryElement = SCNGeometryElement()
    var triangleGeometry = SCNGeometry()
    
    var outlineGeometryElements = [SCNGeometryElement]()
    var outlineGeometry = SCNGeometry()
    
    var yellowMaterial = SCNMaterial()
    
    var corners = [SCNVector3]()
    var textureSize = 0
    var layer:Int
    
    public init(model:CameraModel, qLL:Quaternion, imageId:String) {
        self.model = model
        self.qLL = qLL
        self.imageId = imageId
        self.cameraId = Mission.currentMission().getCameraId(imageId: imageId)
        self.layer = Mission.currentMission().layer(cameraId: cameraId)
        
        self.addCorner([0.0, 0.0])        //upper left
        self.addCorner([0.0, model.ydim]) //lower left
        self.addCorner([model.xdim, 0.0]) //upper right
        self.addCorner([model.xdim, model.ydim]) //lower right
        
        quadVertexSource = SCNGeometrySource(vertices: corners)
        let uvSource = SCNGeometrySource(textureCoordinates:
            [CGPoint(x:0,y:0), CGPoint(x:0,y:1), CGPoint(x:1,y:0), CGPoint(x:1,y:1)])
        triangleGeometryElement = SCNGeometryElement(indices: triangleIndices, primitiveType: .triangleStrip)
        triangleGeometry = SCNGeometry(sources: [quadVertexSource, uvSource], elements: [triangleGeometryElement])

        outlineGeometryElements = [
            SCNGeometryElement(indices:[Int32(0), Int32(1)], primitiveType: .line),
            SCNGeometryElement(indices:[Int32(1), Int32(3)], primitiveType: .line),
            SCNGeometryElement(indices:[Int32(2), Int32(3)], primitiveType: .line),
            SCNGeometryElement(indices:[Int32(2), Int32(0)], primitiveType: .line)
        ]
        outlineGeometry = SCNGeometry(sources: [quadVertexSource], elements: outlineGeometryElements)
        yellowMaterial.diffuse.contents = ImageQuad.yellow
        outlineGeometry.firstMaterial = yellowMaterial
        node = SCNNode(geometry: outlineGeometry)
    }
    
    func cameraFOVRadians() -> Double {
        if let fov = Mission.currentMission().cameraFOVs[cameraId] {
            return fov
        }
        return 0.0
    }
    
    func addCorner(_ pos:[Double]) {
        let distance = Double(layer+5)
        var pos3 = [0.0,0.0,0.0]
        var vec3 = [0.0,0.0,0.0]
        var pos3LL = [0.0,0.0,0.0]
        var pinitial = [0.0,0.0,0.0]
        var pfinal = [0.0,0.0,0.0]
        var llRotq = [0.0,0.0,0.0,0.0]
        llRotq[0] = qLL.w
        llRotq[1] = qLL.x
        llRotq[2] = qLL.y
        llRotq[3] = qLL.z
        var xrotq = Quaternion.identity
        quatva(xAxis, Double.pi/2, &xrotq)
        var zrotq = Quaternion.identity
        quatva(zAxis, -Double.pi/2, &zrotq);
        
        model.cmod_2d_to_3d(pos2: pos, pos3:&pos3, uvec3:&vec3)
        sub(pos3, mast, &pos3)
        scale(distance, vec3, &vec3)
        add(pos3, vec3, &pos3)
        multqv(llRotq, pos3, &pos3LL)
        multqv(zrotq, pos3LL, &pinitial)
        multqv(xrotq, pinitial, &pfinal)
        corners.append(SCNVector3Make(Float(pfinal[0]), Float(pfinal[1]), Float(pfinal[2])))
    }
}
