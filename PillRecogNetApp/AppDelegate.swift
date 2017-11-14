//
//  AppDelegate.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 17/10/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	lazy var coreDataStack = CoreDataStack(modelName: "PillRecogNetApp")


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		_ = coreDataStack.mainContext
		
		guard let navigationController = window!.rootViewController as? UINavigationController, let takePhotoController = navigationController.topViewController as? TakePhotoViewController else {
			fatalError("Impossibile propagare lo stack Core Data al view controller principale.!")
		}
		takePhotoController.coreDataStack = coreDataStack
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
		coreDataStack.save(usingChildContext: false)
	}

}

