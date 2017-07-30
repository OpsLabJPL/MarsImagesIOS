//
//  SwinjectStoryboardSetup.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {
    
    class func setup() {
        defaultContainer.storyboardInitCompleted(MarsImageTableViewController.self) { resolver,controller in
            controller.catalog = resolver.resolve(MarsImageCatalog.self)
        }
        
        defaultContainer.storyboardInitCompleted(MarsImageViewController.self) { resolver, controller in
            controller.catalog = resolver.resolve(MarsImageCatalog.self)
        }
        
        defaultContainer.register(MarsImageCatalog.self) { _ in EvernoteMarsImageCatalog(missionName: Mission.currentMissionName()) }
            .inObjectScope(.container) //make it a singleton        
    }
}
