//
//  AppDelegate.swift
//  SwiftUIAppDelegate
//
//  Created by Nils Bergmann on 19/09/2020.
//

import UIKit
import SwiftyBeaver

let log = SwiftyBeaver.self

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    lazy var fileManager: FileManager = .default;
    var logLocation: URL?;
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let logFormat: String = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M $X"
        
        let console: ConsoleDestination = ConsoleDestination()
        console.format = logFormat;
        log.addDestination(console)
                
        DispatchQueue(label: "log").async {
            if let url: URL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let logUrl: URL = url.appendingPathComponent("Log/", isDirectory: true).appendingPathComponent("sitnu-ios.log", isDirectory: false);
                self.logLocation = logUrl;
                let file = FileDestination(logFileURL: logUrl);
                file.format = logFormat;
                log.addDestination(file)
                log.debug("Added file destination")
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

