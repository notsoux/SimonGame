//
//  AppDelegate.swift
//  rhythm
//
//  Created by William Pompei on 21/10/2017.
//  Copyright © 2017 William Pompei. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let gameCoordinator = GameCoordinator()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame:  UIScreen.main.bounds)
        let rootViewcontroller = gameCoordinator.start()
        window?.rootViewController = rootViewcontroller
        window?.makeKeyAndVisible()
        return true
    }
}

