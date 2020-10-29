//
//  AppDelegate.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 27/04/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import UIKit
import GoogleMaps
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyCuGHmRXRd5RMJaseiDZxJh0DcxGF5CdQI")
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: {result, error in
                if !result {
                    let alert = UIAlertController(title: "Rent 24 Notifications", message: "App can't send alerts when a new job is assigned or updated", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                }
                if let error = error {
                    print("Error occured when asking for notification permission", error)
                }
            })
        } else {
            // Fallback on earlier versions
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: UIUserNotificationType(rawValue: UIUserNotificationType.sound.rawValue | UIUserNotificationType.badge.rawValue | UIUserNotificationType.alert.rawValue), categories: nil))
        }
        application.registerForRemoteNotifications()
        return true
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
        if let type =  notification.userInfo?["type"] as? String,
            "ACIVE_JOB_MAP_REQUEST" == type {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeTabController") as! UITabBarController
            homeVC.selectedIndex = 1
            if let pickupLat = notification.userInfo?["pickupLat"] as? String,
                let pickupLong = notification.userInfo?["pickupLong"] as? String,
                let dropOffLat = notification.userInfo?["dropOffLong"] as? String,
                let dropOffLong = notification.userInfo?["dropOffLong"] as? String,
                let jobId = notification.userInfo?["jobId"] as? Int,
                let mapVC = homeVC.selectedViewController as? MapViewController {

                let trip = JobTrip(id: jobId, rcmId: "", pickupLocation: "", pickupLat: pickupLat, pickupLong: pickupLong, dropoffLocation: "", startTime: "", jobType: "", task: "", dropoffLat: dropOffLat, dropoffLong: dropOffLong, status: "", route: "", stops: [])
                mapVC.updateMap(for: trip)
                if 2 == trip.statusInt {
                    let url = URL(string: "http://www.technidersolutions.com/sandbox/rmc/public/api/job/status")!
                    var request = URLRequest(url: url)
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    let token = getTokenFromKeychain()
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    let body = JobStatusRequest(jobId: trip.id, status: "jobstart")
                    let encoder = JSONEncoder()
                    request.httpBody = try? encoder.encode(body)
                    request.httpMethod = "POST"
                    let configuration = URLSessionConfiguration.default
                    if #available(iOS 11.0, *) {
                        configuration.waitsForConnectivity = true
                    }
                    let session = URLSession(configuration: configuration)
                    let task = session.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print("error occured", error.localizedDescription)
                            return
                        }
                        guard let httpResponse = response as? HTTPURLResponse,
                            (200...299).contains(httpResponse.statusCode)
                            else {
                                print("response error", response.debugDescription)
                                return
                        }
                        if let data = data {
                            let decoder = JSONDecoder()
                            if let responseJson = try? decoder.decode(StatusResponse.self, from: data) {
                                print("response data", responseJson)
                            }
                        }
                    }
                    task.resume()
                }
            }
            window?.rootViewController = homeVC
        }
    }

    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("device token", deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("error with remote notification registration", error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("notification", userInfo)
    }

    private func getTokenFromKeychain() -> String {
        let searchQuery: [CFString:Any] = [kSecClass: kSecClassGenericPassword,
                                           kSecAttrGeneric: "com.rent24.driver.identifier".data(using: .utf8)!,
                                           kSecAttrAccount: "driver".data(using: .utf8)!,
                                           kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                           kSecReturnAttributes: kCFBooleanTrue!,
                                           kSecMatchLimit: kSecMatchLimitOne,
                                           kSecReturnData: kCFBooleanTrue!]
        var item: CFTypeRef?
        let searchStatus = SecItemCopyMatching(searchQuery as CFDictionary, &item)
        if errSecSuccess == searchStatus {
            guard let foundItem = item as? [String:Any],
                let tokenData = foundItem[kSecValueData as String] as? Data,
                let token = String(data: tokenData, encoding: .utf8)
                else {
                    return ""
            }
            return token
        }
        return ""
    }
}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .alert, .sound])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("token", fcmToken)
    }
}
