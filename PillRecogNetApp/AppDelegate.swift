//
//  AppDelegate.swift
//  PillRecogNetApp
//
//  Created by Matteo Del Vecchio on 17/10/17.
//  Copyright © 2017 Matteo Del Vecchio. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	// Initialize Core Data stack to save classifications
	lazy var coreDataStack = CoreDataStack(modelName: "PillRecogNetApp")


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		notificationSetUp()
		
		// Initialize main context
		_ = coreDataStack.mainContext
		
		// Propagate Core Data stack to the controllers
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
	
	func notificationSetUp() {
		// Notifications settings
		let center = UNUserNotificationCenter.current()
		let options:UNAuthorizationOptions = [.alert, .sound]
		center.requestAuthorization(options: options) { (granted, error) in }
		center.delegate = self
		
		let disableAction = UNNotificationAction(identifier: "DisableNotificationAction", title: "Disabilita Notifiche", options: [])
		let cancelAction = UNNotificationAction(identifier: UNNotificationDismissActionIdentifier, title: "Chiudi", options: [])
		
		let wishCategory = UNNotificationCategory(identifier: "PillNotificationCategory", actions: [disableAction, cancelAction], intentIdentifiers: [], options: [])
		center.setNotificationCategories([wishCategory])
		
		guard !UserDefaults.standard.bool(forKey: "ResetNotification") else { return }
		
		UserDefaults.standard.set(true, forKey: "ResetNotification")
		center.removeAllPendingNotificationRequests()
		center.removeAllDeliveredNotifications()
	}
	
	func disableNotificationForPill(info: [String:String]) {
		print(#function)
		if let identifier = info["ClassificationID"] {
			print(identifier)
			let center = UNUserNotificationCenter.current()
			center.removeDeliveredNotifications(withIdentifiers: [identifier])
			center.removePendingNotificationRequests(withIdentifiers: [identifier])
		}
	}

}

extension AppDelegate: UNUserNotificationCenterDelegate {
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.sound, .alert])
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		
		let userInfo = response.notification.request.content.userInfo as! [String:String]
		let categoryIdentifier = response.notification.request.content.categoryIdentifier
		
		if categoryIdentifier == "PillNotificationCategory" {
			switch response.actionIdentifier {
			case "DisableNotificationAction":
				disableNotificationForPill(info: userInfo)
			default: break
			}
		}
		
		completionHandler()
	}
}

