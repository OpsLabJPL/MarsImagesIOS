//
//  MosaicLoader.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 9/17/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SceneKit

class MosaicLoader {
    
    var rmc:(Int,Int)
    var catalog:MarsImageCatalog
    
    init(rmc:(Int,Int), catalog:MarsImageCatalog) {
        self.rmc = rmc
        self.catalog = catalog
    }
    
    func addImagesToScene(_ rmc: (Int,Int), scene: SCNScene) {
//        _rmc = rmc;
//        id<MarsRover> mission = [MarsImageNotebook instance].mission;
//        site_index = [[rmc objectAtIndex:0] intValue];
//        drive_index = [[rmc objectAtIndex:1] intValue];
//        qLL = [mission localLevelQuaternion:site_index drive:drive_index];
//        [MarsImageNotebook instance].searchWords = [NSString stringWithFormat:@"RMC %06d-%06d", site_index, drive_index];
//        [[MarsImageNotebook instance] reloadNotes]; //rely on the resultant note load notifications to populate images in the scene
        self.rmc = rmc
        catalog.searchWords = String(format:"%06d-%06d", rmc.0, rmc.1)
        catalog.reload()
    }
}
