//
//  Model.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

protocol Model {

    var xdim:Double {get set}
    var ydim:Double {get set}

    func cmod_2d_to_3d(pos2:[Double], pos3: inout [Double], uvec3: inout [Double])

    func cmod_3d_to_2d(pos3:[Double], range: inout [Double], pos2: inout [Double])

}
