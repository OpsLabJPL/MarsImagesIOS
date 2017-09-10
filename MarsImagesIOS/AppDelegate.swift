//
//  AppDelegate.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/27/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import UIKit
import SwinjectStoryboard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var catalog:MarsImageCatalog?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if let options = launchOptions {
            let value = options[.localNotification] as? UILocalNotification
            if let notification = value {
                self.application(application, didReceive: notification)
            }
        } else {
            let settings = UIUserNotificationSettings(types: .alert, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        catalog = SwinjectStoryboard.defaultContainer.resolve(MarsImageCatalog.self)
        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types == [] {
            application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            return
        }
        
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        var soldataNeedsWriteUpdate = false
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let path = paths.appending("/latestsols.plist")
        var soldata = NSMutableDictionary()
        let dictFromFile = NSMutableDictionary(contentsOfFile:path)
        if let dictFromFile = dictFromFile {
            soldata = dictFromFile
        } else {
            soldataNeedsWriteUpdate = true
        }
        let oppyLastKnownSol = soldata.object(forKey: Mission.OPPORTUNITY)
        let mslLastKnownSol = soldata.object(forKey: Mission.CURIOSITY)
        
        
        catalog?.mission = Mission.OPPORTUNITY
        catalog?.reload()
        if let oppyImageSet = catalog?.imagesets[0] {
            let oppyLatestSol = oppyImageSet.sol
            if let oppyLatestSol = oppyLatestSol {
                soldata.setValue(oppyLatestSol, forKey: Mission.OPPORTUNITY)
                if oppyLastKnownSol != nil && oppyLatestSol > oppyLastKnownSol as! Int {
                    soldataNeedsWriteUpdate = true
                    displayLocalNotification( "New images from Opportunity sol \(oppyLatestSol) have arrived!")
                }
            }
        }
        
        catalog?.mission = Mission.CURIOSITY
        catalog?.reload()
        if let mslImageSet = catalog?.imagesets[0] {
            let mslLatestSol = mslImageSet.sol
            if let mslLatestSol = mslLatestSol {
                soldata.setValue(mslLatestSol, forKey: Mission.CURIOSITY)
                if mslLastKnownSol != nil && mslLatestSol > mslLastKnownSol as! Int {
                    soldataNeedsWriteUpdate = true
                    displayLocalNotification("New images from Curiosity sol \(mslLatestSol) have arrived!")
                }
            }
        }
        
        if soldataNeedsWriteUpdate {
            soldata.write(toFile: path, atomically: true)
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
    
    func displayLocalNotification(_ message:String) {
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 0)
        notification.timeZone = Calendar.current.timeZone
        notification.alertBody = message
        notification.hasAction = true
        notification.alertAction = "View"
        UIApplication.shared.scheduleLocalNotification(notification)
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

