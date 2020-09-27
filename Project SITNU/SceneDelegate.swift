//
//  SceneDelegate.swift
//  SwiftUIAppDelegate
//
//  Created by Nils Bergmann on 19/09/2020.
//

import UIKit
import SwiftUI
import WatchConnectivity

class SceneDelegate: UIResponder, UIWindowSceneDelegate, WCSessionDelegate {
    private lazy var watchStore = WatchStore()
    private let session: WCSession = .default;
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        log.debug("WCSession activated", context: ["activationState": activationState.rawValue])
        self.sessionWatchStateDidChange(session);
        let context = session.applicationContext;
        if let sharedContext = try? SharedContext(from: context) {
            DispatchQueue.main.async {
                self.watchStore.accounts = sharedContext.accounts;
                self.watchStore.canSendMessages = session.isReachable;
            }
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata: [String: Any] = file.metadata else {
            log.warning("Discard transferred file, because metadata is missing");
            return;
        }
        guard let metaType: String = metadata["type"] as? String else {
            log.warning("Discard transferred file, because type metadata is missing");
            return;
        }
        if metaType == "log" {
            guard let targetDirRoot: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                log.error("Missing target dir root")
                return;
            }
            let targetDir = targetDirRoot.appendingPathComponent("Log/", isDirectory: true).appendingPathComponent(file.fileURL.lastPathComponent, isDirectory: false);
            log.info("Move transferred file", context: ["at": file.fileURL, "to": targetDir]);
            do {
                try FileManager.default.moveItem(at: file.fileURL, to: targetDir);
                DispatchQueue.main.async {
                    self.watchStore.updateLogFiles();
                }
            } catch(let error) {
                log.error("Failed to move transferred file", context: ["error": error]);
            }
        } else {
            log.warning("Discard transferred file, because type metadata is unknown");
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive()")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate()")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        log.debug("WCSession state changed", context: ["isWatchAppInstalled": session.isWatchAppInstalled, "isPaired": session.isPaired])
        DispatchQueue.main.async {
            self.watchStore.available = session.isWatchAppInstalled && session.isPaired;
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.watchStore.canSendMessages = session.isReachable;
        }
    }
    
    func sync(context: [String: Any]) throws {
        if WCSession.isSupported() && session.isWatchAppInstalled && session.isPaired {
            try self.session.updateApplicationContext(context);
        } else {
            print("Can't sync");
        }
    }

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        self.watchStore.syncCallback = { context in
            do {
                try self.sync(context: context)
            } catch (let error) {
                print("Error with syncCallback: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.async {
            self.watchStore.updateLogFiles();
        }
        
        self.session.delegate = self;
        
        if WCSession.isSupported() {
            self.session.activate();
        }
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = RootView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView.environmentObject(self.watchStore))
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

