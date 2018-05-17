//
//  AppDelegate.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import Swinject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let container:Container = {
        let container = Container()
        container.register(MarsImageCatalog.self, name: Mission.OPPORTUNITY) { _ in EvernoteMarsImageCatalog(missionName: Mission.OPPORTUNITY)}
        container.register(MarsImageCatalog.self, name: Mission.CURIOSITY) { _ in EvernoteMarsImageCatalog(missionName: Mission.CURIOSITY)}
        container.register(MarsImageCatalog.self, name: Mission.SPIRIT) { _ in EvernoteMarsImageCatalog(missionName: Mission.SPIRIT)}
        return container
    }()
    var catalogs:[String:MarsImageCatalog] = [:]
    var backgroundTask:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var soldata = NSMutableDictionary()
    var fetchCompletionHandler:((UIBackgroundFetchResult) -> Void)?
    var path:String?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Log.initLog()
        
        // Override point for customization after application launch.

        catalogs[Mission.OPPORTUNITY] = container.resolve(MarsImageCatalog.self, name:Mission.OPPORTUNITY)
        catalogs[Mission.CURIOSITY] = container.resolve(MarsImageCatalog.self, name:Mission.CURIOSITY)
        catalogs[Mission.SPIRIT] = container.resolve(MarsImageCatalog.self, name:Mission.SPIRIT)

        if let options = launchOptions {
            let value = options[.localNotification] as? UILocalNotification
            if let notification = value {
                self.application(application, didReceive: notification)
            }
        } else {
            let settings = UIUserNotificationSettings(types: .alert, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        path = paths.appending("latestsols.plist")

        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types == [] {
            application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            return
        }
        
        application.setMinimumBackgroundFetchInterval(15*60)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        fetchCompletionHandler = completionHandler
        
        self.backgroundTask = application.beginBackgroundTask(expirationHandler: {
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        })
        let dictFromFile = NSMutableDictionary(contentsOfFile:path!)
        if let dictFromFile = dictFromFile {
            soldata = dictFromFile
        }
        NotificationCenter.default.addObserver(self, selector: #selector(checkOppyImages), name: .endImagesetLoading, object: nil)
        self.catalogs[Mission.OPPORTUNITY]?.reload()
    }
    
    @objc func checkOppyImages() {
        DispatchQueue.global().async {
            let oppyLastKnownSol = self.soldata.object(forKey: Mission.OPPORTUNITY)
            if let oppyImages = self.catalogs[Mission.OPPORTUNITY] {
                let oppyImageSet = oppyImages.imagesets[0]
                let oppyLatestSol = oppyImageSet.sol
                if let oppyLatestSol = oppyLatestSol {
                    self.soldata.setValue(oppyLatestSol, forKey: Mission.OPPORTUNITY)
                    if oppyLastKnownSol != nil && oppyLatestSol > oppyLastKnownSol as! Int {
                        self.displayLocalNotification(UIApplication.shared, message: "New images from Opportunity sol \(oppyLatestSol) have arrived!")
                    }
                }
            }
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(self, selector: #selector(self.checkMslImages), name: .endImagesetLoading, object: nil)
            self.catalogs[Mission.CURIOSITY]?.reload()
        }
    }
    
    @objc func checkMslImages() {
        let mslLastKnownSol = soldata.object(forKey: Mission.CURIOSITY)
        if let mslImages = catalogs[Mission.CURIOSITY] {
            if mslImages.imagesets.count > 0 {
                let mslImageSet = mslImages.imagesets[0]
                let mslLatestSol = mslImageSet.sol
                if let mslLatestSol = mslLatestSol {
                    soldata.setValue(mslLatestSol, forKey: Mission.CURIOSITY)
                    if mslLastKnownSol != nil && mslLatestSol > mslLastKnownSol as! Int {
                        displayLocalNotification(UIApplication.shared, message:"New images from Curiosity sol \(mslLatestSol) have arrived!")
                    }
                }
            }
        }
        NotificationCenter.default.removeObserver(self)
        
        soldata.write(toFile: path!, atomically: true)
        fetchCompletionHandler!(.newData)
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }
    
    func displayLocalNotification(_ application: UIApplication, message:String) {
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 0)
        notification.timeZone = Calendar.current.timeZone
        notification.alertBody = message
        notification.hasAction = true
        notification.alertAction = "View"
        application.scheduleLocalNotification(notification)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        //
    }
}

