//
//  CAHVOR.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class CAHVOR : CAHV {
    
    var o:[Double] = []
    var r:[Double] = []

    override func cmod_2d_to_3d(pos2: [Double], pos3: inout [Double], uvec3: inout [Double]) {
        return super.cmod_2d_to_3d(pos2: pos2, pos3: &pos3, uvec3: &uvec3)
        //TODO
    }
    
    override func cmod_3d_to_2d(pos3: [Double], range: inout [Double], pos2: inout [Double]) {
        return super.cmod_3d_to_2d(pos3: pos3, range: &range, pos2: &pos2)
        //TODO
    }
}
