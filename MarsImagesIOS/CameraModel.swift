//
//  CameraModel.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import SwiftyJSON

class CameraModel {

    static func model(_ json: JSON) -> Model {
        var returnedModel: Model?
        var type = ""
        var mtype:Double
        var mparm:Double
        var width:Double
        var height:Double
        
        type = json["type"].stringValue
        let comps = json["components"].dictionaryValue
        let cDict = comps["c"]?.dictionary
        let aDict = comps["a"]?.dictionary
        let hDict = comps["h"]?.dictionary
        let vDict = comps["v"]?.dictionary
        let oDict = comps["o"]?.dictionary
        let rDict = comps["r"]?.dictionary
        let eDict = comps["e"]?.dictionary
        mtype = comps["t"]!.doubleValue
        mparm = comps["p"]!.doubleValue
        
        let area = comps["area"]!.arrayValue
        width = area[0].doubleValue
        height = area[1].doubleValue

        if type == "CAHV" {
            let cahv = CAHV()
            cahv.c = [cDict!["x"]!.doubleValue, cDict!["y"]!.doubleValue, cDict!["z"]!.doubleValue]
            cahv.a = [aDict!["x"]!.doubleValue, aDict!["y"]!.doubleValue, aDict!["z"]!.doubleValue]
            cahv.h = [hDict!["x"]!.doubleValue, hDict!["y"]!.doubleValue, hDict!["z"]!.doubleValue]
            cahv.v = [vDict!["x"]!.doubleValue, vDict!["y"]!.doubleValue, vDict!["z"]!.doubleValue]
            returnedModel = cahv;
        } else if type == "CAHVOR" {
            let cahvor = CAHVOR()
            cahvor.c = [cDict!["x"]!.doubleValue, cDict!["y"]!.doubleValue, cDict!["z"]!.doubleValue]
            cahvor.a = [aDict!["x"]!.doubleValue, aDict!["y"]!.doubleValue, aDict!["z"]!.doubleValue]
            cahvor.h = [hDict!["x"]!.doubleValue, hDict!["y"]!.doubleValue, hDict!["z"]!.doubleValue]
            cahvor.v = [vDict!["x"]!.doubleValue, vDict!["y"]!.doubleValue, vDict!["z"]!.doubleValue]
            cahvor.o = [oDict!["x"]!.doubleValue, oDict!["y"]!.doubleValue, oDict!["z"]!.doubleValue]
            cahvor.r = [rDict!["x"]!.doubleValue, rDict!["y"]!.doubleValue, rDict!["z"]!.doubleValue]
            returnedModel = cahvor
        } else if type == "CAHVORE" {
            let cahvore = CAHVORE()
            cahvore.c = [cDict!["x"]!.doubleValue, cDict!["y"]!.doubleValue, cDict!["z"]!.doubleValue]
            cahvore.a = [aDict!["x"]!.doubleValue, aDict!["y"]!.doubleValue, aDict!["z"]!.doubleValue]
            cahvore.h = [hDict!["x"]!.doubleValue, hDict!["y"]!.doubleValue, hDict!["z"]!.doubleValue]
            cahvore.v = [vDict!["x"]!.doubleValue, vDict!["y"]!.doubleValue, vDict!["z"]!.doubleValue]
            cahvore.o = [oDict!["x"]!.doubleValue, oDict!["y"]!.doubleValue, oDict!["z"]!.doubleValue]
            cahvore.r = [rDict!["x"]!.doubleValue, rDict!["y"]!.doubleValue, rDict!["z"]!.doubleValue]
            cahvore.e = [eDict!["x"]!.doubleValue, eDict!["y"]!.doubleValue, eDict!["z"]!.doubleValue]
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

}
