//
//  CAHV.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class CAHV: Model {
    
    var xdim:Double = 0
    var ydim:Double = 0
    var c:[Double] = []
    var a:[Double] = []
    var h:[Double] = []
    var v:[Double] = []
    
    func size() -> [Double] {
        return [xdim, ydim]
    }
    
    func setC(x:Double, y:Double, z:Double) {
        c = [x, y, z]
    }

    func setA(x:Double, y:Double, z:Double) {
        a = [x, y, z]
    }

    func setH(x:Double, y:Double, z:Double) {
        h = [x, y, z]
    }

    func setV(x:Double, y:Double, z:Double) {
        v = [x, y, z]
    }

    func cmod_2d_to_3d(pos2:[Double], pos3: inout [Double], uvec3: inout [Double]) {
        var f = [0.0, 0.0, 0.0]
        var g = [0.0, 0.0, 0.0]
        var magi: Double
        var t = [0.0, 0.0, 0.0]
        
        /* The projection point is merely the C of the camera model */
        copy(c, &pos3)
        
        /* Calculate the projection ray assuming normal vector directions */
        scale(pos2[1], a, &f)
        sub(v, f, &f)
        scale(pos2[0], a, &g)
        sub(h, g, &g)
        cross(f, g, &uvec3)
        magi = mag(uvec3)
        magi = 1.0/magi
        
        scale(magi, uvec3, &uvec3)

        /* Check and optionally correct for vector directions */
        cross(v, h, &t)
        if (dot(t,a) < 0) {
            scale(-1.0, uvec3, &uvec3)
        }
    }
    
    func cmod_3d_to_2d(pos3:[Double], range: inout [Double], pos2: inout [Double]) {
        var d = [0.0, 0.0, 0.0]
        var r_1: Double
        
        /* Calculate the projection */
        sub(pos3, c, &d)
        range[0] = dot(d,a)
        r_1 = 1.0 / range[0]
        pos2[0] = dot(d,h) * r_1
        pos2[1] = dot(d,v) * r_1
    }
}
