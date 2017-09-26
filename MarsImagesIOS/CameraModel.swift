//
//  Model.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol CameraModel {
    
    var xdim:Double {get set}
    var ydim:Double {get set}
    
    func cmod_2d_to_3d(pos2:[Double], pos3: inout [Double], uvec3: inout [Double])
    
    func cmod_3d_to_2d(pos3:[Double], range: inout [Double], pos2: inout [Double])
}

class CameraModelUtils {
    
    static func model(_ json: JSON) -> CameraModel {
        var returnedModel: CameraModel?
        var type = ""
        var mtype:Double
        var mparm:Double
        var width:Double
        var height:Double
        
        let model = json.arrayValue[1]
        let dimensions = json.arrayValue[0]
        type = model["type"].stringValue
        let comps = model["components"].dictionaryValue
        let cDict = comps["c"]?.arrayValue
        let aDict = comps["a"]?.arrayValue
        let hDict = comps["h"]?.arrayValue
        let vDict = comps["v"]?.arrayValue
        let oDict = comps["o"]?.arrayValue
        let rDict = comps["r"]?.arrayValue
        let eDict = comps["e"]?.arrayValue
        mtype = comps["t"]?.doubleValue ?? 0.0
        mparm = comps["p"]?.doubleValue ?? 0.0
        
        let area = dimensions["area"].arrayValue
        width = area[0].doubleValue
        height = area[1].doubleValue
        
        if type == "CAHV" {
            let cahv = CAHV()
            cahv.c = [cDict![0].doubleValue, cDict![1].doubleValue, cDict![2].doubleValue]
            cahv.a = [aDict![0].doubleValue, aDict![1].doubleValue, aDict![2].doubleValue]
            cahv.h = [hDict![0].doubleValue, hDict![1].doubleValue, hDict![2].doubleValue]
            cahv.v = [vDict![0].doubleValue, vDict![1].doubleValue, vDict![2].doubleValue]
            returnedModel = cahv;
        } else if type == "CAHVOR" {
            let cahvor = CAHVOR()
            cahvor.c = [cDict![0].doubleValue, cDict![1].doubleValue, cDict![2].doubleValue]
            cahvor.a = [aDict![0].doubleValue, aDict![1].doubleValue, aDict![2].doubleValue]
            cahvor.h = [hDict![0].doubleValue, hDict![1].doubleValue, hDict![2].doubleValue]
            cahvor.v = [vDict![0].doubleValue, vDict![1].doubleValue, vDict![2].doubleValue]
            cahvor.o = [oDict![0].doubleValue, oDict![1].doubleValue, oDict![2].doubleValue]
            cahvor.r = [rDict![0].doubleValue, rDict![1].doubleValue, rDict![2].doubleValue]
            returnedModel = cahvor
        } else if type == "CAHVORE" {
            let cahvore = CAHVORE()
            cahvore.c = [cDict![0].doubleValue, cDict![1].doubleValue, cDict![2].doubleValue]
            cahvore.a = [aDict![0].doubleValue, aDict![1].doubleValue, aDict![2].doubleValue]
            cahvore.h = [hDict![0].doubleValue, hDict![1].doubleValue, hDict![2].doubleValue]
            cahvore.v = [vDict![0].doubleValue, vDict![1].doubleValue, vDict![2].doubleValue]
            cahvore.o = [oDict![0].doubleValue, oDict![1].doubleValue, oDict![2].doubleValue]
            cahvore.r = [rDict![0].doubleValue, rDict![1].doubleValue, rDict![2].doubleValue]
            cahvore.e = [eDict![0].doubleValue, eDict![1].doubleValue, eDict![2].doubleValue]
            cahvore.t = mtype
            cahvore.p = mparm
            returnedModel = cahvore
        }
        if var returnedModel = returnedModel {
            returnedModel.xdim = width
            returnedModel.ydim = height
            return returnedModel;
        }
        return CAHV()
    }
    
    static func pointingVector(_ modelJson:JSON) -> [Double] {
        return vectorFromJSON(tripleKey: "camera_vector", modelJson: modelJson)
    }
    
    static func origin(_ modelJson:JSON) -> [Double] {
        return vectorFromJSON(tripleKey: "origin", modelJson: modelJson)
    }
    
    private static func vectorFromJSON(tripleKey:String, modelJson:JSON) -> [Double] {
        let model = modelJson.arrayValue[1]
        let comps = model[tripleKey]
        let x:Double = Double(comps.arrayValue[0].stringValue)!
        let y:Double = Double(comps.arrayValue[1].stringValue)!
        let z:Double = Double(comps.arrayValue[2].stringValue)!
        return [x,y,z]
    }
    
}

