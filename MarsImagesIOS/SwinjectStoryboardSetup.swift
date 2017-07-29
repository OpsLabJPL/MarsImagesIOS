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
//        defaultContainer.storyboardInitCompleted(ChannelsViewController.self) { resolver,controller in
//            controller.chatClient = resolver.resolve(ChatClient.self)
//        }
//        defaultContainer.storyboardInitCompleted(ChannelChatViewController.self) { resolver,controller in
//            controller.chatClient = resolver.resolve(ChatClient.self)
//        }
        
        defaultContainer.register(MarsImageCatalog.self) { _ in EvernoteMarsImageCatalog(missionName: Mission.currentMissionName()) }
            .inObjectScope(.container) //make it a singleton
        
//        defaultContainer.register(ChatClient.self) { resolver in
//            ChatClient(networking: resolver.resolve(ChatNetworking.self)!)
//            }
//            .inObjectScope(.container)
    }
}
