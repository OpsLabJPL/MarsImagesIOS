//
//  AppDelegate.m
//  Mars-Images
//
//  Created by Mark Powell on 11/17/12.
//  Copyright (c) 2012 Jet Propulsion Laboratory/California Institute of Technology. All rights reserved.
//

#import "AppDelegate.h"
#import "MarsSidePanelController.h"
#import "MMDrawerController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _lastSleepTime = nil;
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:50 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    UIStoryboard* storyboard = self.window.rootViewController.storyboard; 
    
    UINavigationController* tableNavVC = (UINavigationController*)[storyboard instantiateViewControllerWithIdentifier:@"tableNavController"];
    UINavigationController* imageNavVC = (UINavigationController *) self.window.rootViewController;
    
    self.drawerController = [[MMDrawerController alloc]
                                             initWithCenterViewController:imageNavVC
                                             leftDrawerViewController:tableNavVC];
    self.window.rootViewController = self.drawerController;
    
    [self.drawerController setShowsShadow:NO];
    [self.drawerController setRestorationIdentifier:@"MMDrawer"];
    [self.drawerController setMaximumRightDrawerWidth:200.0];
    [self.drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModePanningNavigationBar];
    [self.drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModePanningNavigationBar];
    [self.drawerController setCenterHiddenInteractionMode:MMDrawerOpenCenterInteractionModeFull];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.lastSleepTime = [[NSDate date] copy];
    NSLog(@"sleeptime %f", _lastSleepTime.timeIntervalSince1970);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //compare the time it was backgrounded and refresh notes if the time is over a threshold like 30 minutes
    if (self.lastSleepTime != nil) {
        NSTimeInterval elapsedSeconds = -[self.lastSleepTime timeIntervalSinceNow];
        NSLog(@"elapsed seconds %f", elapsedSeconds);
        if (elapsedSeconds > 30*60) { //30 minutes
            NSLog(@"reloading...");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"EnteredForeground"
                                                                object:nil];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
