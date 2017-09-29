//
//  ImageQuad.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 9/26/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SceneKit

class ImageQuad {
    
    let textureCoords = [0.0, 1, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0]
    let triangleIndices:[Int32] = [0,1,2,1,3,2]
    
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
    
    var center = SCNVector3()
    var boundingSphereRadius = 0.0
    var corners = [SCNVector3]()
    var deltas = [Double]()
    var textureSize = 16
    var layer:Int
    
    public init(model:CameraModel, qLL:Quaternion, imageId:String) {
        self.model = model
        self.qLL = qLL
        self.imageId = imageId
        self.cameraId = Mission.currentMission().getCameraId(imageId: imageId)
        self.layer = Mission.currentMission().layer(cameraId: cameraId)
        
        self.addCorner([0.0, model.ydim])
        self.addCorner([model.xdim, model.ydim])
        self.addCorner([0.0, 0.0])
        self.addCorner([model.xdim, 0.0])
        center.x = (corners[0].x+corners[2].x)/2
        center.y = (corners[0].y+corners[2].y)/2
        center.z = (corners[0].z+corners[2].z)/2
        
        quadVertexSource = SCNGeometrySource(vertices: corners)
        triangleGeometryElement = SCNGeometryElement(indices: triangleIndices, primitiveType: .triangles)
        triangleGeometry = SCNGeometry(sources: [quadVertexSource], elements: [triangleGeometryElement])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow

        triangleGeometry.firstMaterial = material
        
        outlineGeometryElements = [
            SCNGeometryElement(indices:[Int32(0), Int32(1)], primitiveType: .line),
            SCNGeometryElement(indices:[Int32(1), Int32(3)], primitiveType: .line),
            SCNGeometryElement(indices:[Int32(3), Int32(2)], primitiveType: .line),
            SCNGeometryElement(indices:[Int32(2), Int32(0)], primitiveType: .line)
        ]
        outlineGeometry = SCNGeometry(sources: [quadVertexSource], elements: outlineGeometryElements)
        outlineGeometry.firstMaterial = material
        node = SCNNode(geometry: outlineGeometry)
    }
    
    func cameraFOVRadians(cameraId: String) -> Float {
        if let fov = Mission.currentMission().cameraFOVs[cameraId] {
            return Float(fov)
        }
        return 0
    }
    
    func distanceBetween(pt1:SCNVector3, pt2:SCNVector3) -> Float {
        let dx = pt1.x-pt2.x;
        let dy = pt1.y-pt2.y;
        let dz = pt1.z-pt2.z;
        return Float(sqrt(dx*dx+dy*dy+dz*dz))
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
