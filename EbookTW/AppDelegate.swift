//
//  AppDelegate.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let vc = ViewController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        let nav = UINavigationController(rootViewController: vc)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window

        window.tintColor = UIColor.etw_tintColor
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor.etw_tintColor
        UITextField.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).backgroundColor = .white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = .white   // searchBar cancel button

        UserDefaults.standard.register(defaults: [StoreReview.kSearchCount: 0])
        NSUbiquitousKeyValueStore.default.synchronize()

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

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
                return false
        }
        guard let path = components.path else {
            showAlert(msg: "No path")
            return false
        }
        if path != "/search" {
            showAlert(msg: "Not /search")
            return false
        }
        guard let params = components.queryItems else {
            showAlert(msg: "No query")
            return false
        }
        guard let keywordEncoded = params.first(where: { $0.name == "q" } )?.value else {
            showAlert(msg: "No keyword")
            return false
        }
        guard let keywordDecoded = keywordEncoded.removingPercentEncoding else {
            showAlert(msg: "Keyword cannot be decoded")
            return false
        }
        vc.search(keyword: keywordDecoded)
        return true
    }

    private func showAlert(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirm)
        vc.present(alert, animated: true, completion: nil)
    }
}

extension UIColor {

    static let etw_tintColor = UIColor(red:0.05, green:0.70, blue:0.61, alpha:1.0)  // #0EB29B
}
