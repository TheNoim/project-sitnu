//
//  ExtensionDelegate.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 19/09/2020.
//

import WatchKit
import ClockKit
import SwiftyBeaver
import Cache

let log = SwiftyBeaver.self

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    lazy var bgUtility: BackgroundUtility = BackgroundUtility();
        
    var logLocation: URL?;
    
    let fileManager = FileManager.default

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        
        let logFormat: String = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M $X"
        
        let console: ConsoleDestination = ConsoleDestination()
        
        console.format = logFormat;
        
        var file: FileDestination?;
        
        if let url: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logUrl: URL = url.appendingPathComponent("Log/", isDirectory: true).appendingPathComponent("sitnu.log", isDirectory: false);
            file = FileDestination(logFileURL: logUrl);
            self.logLocation = logUrl;
        }
        
        log.addDestination(console)
        
        if file != nil {
            log.addDestination(file!)
            file!.format = logFormat;
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NotificationCenter.default.post(name: Notification.Name("applicationDidBecomeActive"), object: nil);
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    func applicationDidEnterBackground() {
        self.scheduleBackgroundRefreshTasks();
    }

    func scheduleBackgroundRefreshTasks() {
        // If there is a complication on the watch face, the app should get at least four
        // updates an hour. So calculate a target date 30 minutes in the future.
        let targetDate = Date().addingTimeInterval(30.0 * 60.0)
        
        var shouldSchedule = true;
        
        if let backgroundStorage = BackgroundUtility.shared.getBackgroundTaskDiskStorage() {
            if let nextSchedule = try? backgroundStorage.object(forKey: "nextSchedule") {
                if nextSchedule > Date() {
                    log.warning("Do not reschedule background task, because background task is already scheduled", context: ["currentDate": Date(), "nextSchedule": nextSchedule]);
                    shouldSchedule = false;
                }
            }
        } else {
            log.warning("No background task storage")
        }
        
        if !shouldSchedule {
            return;
        }
        
        // Get the shared extension object.
        let watchExtension = WKExtension.shared()
        
        
        log.info("Schedule background refresh", context: ["targetDate": targetDate]);
                
        // Schedule the background refresh task.
        watchExtension.scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in
            // Check for errors.
            if let error = error {
                log.error("Schedule background refresh error", context: ["error": error])
                
                if let backgroundStorage = BackgroundUtility.shared.getBackgroundTaskDiskStorage() {
                    try? backgroundStorage.removeObject(forKey: "nextSchedule");
                }
                return
            }
            
            if let backgroundStorage = BackgroundUtility.shared.getBackgroundTaskDiskStorage() {
                let _ = try? backgroundStorage.setObject(targetDate, forKey: "nextSchedule");
            }
            
            log.info("Background refresh successfully", context: ["targetDate": targetDate])
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                log.info("Start Background Task");
                self.runBackgroundTask(backgroundTask: backgroundTask)
                break;
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func runBackgroundTask(backgroundTask: WKApplicationRefreshBackgroundTask) {
        // Be sure to complete the background task once you’re done.
        self.scheduleBackgroundRefreshTasks();
        self.bgUtility = BackgroundUtility();
        guard let untis = self.bgUtility.getUntisClient() else {
            log.warning("End Background Task, because Untis Client is missing")
            return backgroundTask.setTaskCompletedWithSnapshot(false);
        }
        var lastImportTime: Int64?;
        untis.getLatestImportTime(force: true, cachedHandler: { (importTime) in
            log.info("Background Task: Cached import time.", context: ["importTime": importTime]);
            lastImportTime = importTime;
        }, completion: { result in
            var newImportTime: Int64;
            switch result {
            case.failure(let error):
                log.error("End Background Task, because newImportTime is missing", context: ["error": error]);
                return backgroundTask.setTaskCompletedWithSnapshot(false);
            case .success(let time):
                newImportTime = time;
                break;
            }
            var shouldReload: Bool = false;
            if lastImportTime == nil {
                shouldReload = true;
            } else if lastImportTime! != newImportTime {
                shouldReload = true;
            }
            
            if self.bgUtility.shouldReloadComplications() {
                shouldReload = true;
            }
            
            if shouldReload {
                untis.getTimetable(and: true, cachedHandler: nil) { _ in
                    untis.getTimetable(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, and: true, cachedHandler: nil) { _ in
                        self.bgUtility.reloadComplications();
                        log.info("Background Task: End");
                        backgroundTask.setTaskCompletedWithSnapshot(false);
                    }
                }
            } else {
                log.warning("End Background Task, because shouldReload is false", context: ["shouldReload": shouldReload, "lastImportTime": lastImportTime as Any, "newImportTime": newImportTime]);
                backgroundTask.setTaskCompletedWithSnapshot(false);
            }
        })
    }

}
