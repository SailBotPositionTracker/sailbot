//
//  AppDelegate.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/9/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var timer: Timer = Timer()
    
    var targetBrightness: Double = 0.0
    
    //TODO: check the accuracy of this more closely
    @objc func updateTimer() {
        let bright = CGFloat(targetBrightness)
        if (bright.isLess(than: UIScreen.main.brightness)) {
            UIScreen.main.brightness -= CGFloat(0.05)
        } else if (UIScreen.main.brightness.isLess(than: bright)) {
            UIScreen.main.brightness += CGFloat(0.05)
        }
        if abs(UIScreen.main.brightness - bright) <= 0.01 {
            timer.invalidate()
        }
    }

    var window: UIWindow?
    static var defaultBrightness:Double = 0.5;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.defaultBrightness = Double(UIScreen.main.brightness)
        //TODO: sleeping on main thread might not be the best idea
        Thread.sleep(forTimeInterval: 1.0)
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        targetBrightness = AppDelegate.defaultBrightness
        timer = Timer.scheduledTimer(timeInterval: 0.017, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        AppDelegate.defaultBrightness = Double(UIScreen.main.brightness)
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppDelegate.defaultBrightness = Double(UIScreen.main.brightness)
        targetBrightness = 0.999
        timer = Timer.scheduledTimer(timeInterval: 0.017, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

