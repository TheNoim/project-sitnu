//
//  BackgroundUtility.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 21/09/2020.
//

import Foundation
import Cache
import ClockKit
import Cache

class BackgroundUtility {
    public static let shared = BackgroundUtility();
    
    var untisClient: UntisClient?;
    
    var backgroundTaskDiskStorage: DiskStorage<String, Date>?;
    
    public func getPrimaryAccount() -> UntisAccount? {
        WatchConnectivityStore.default.initialize(withWCSession: false)
        guard let primaryAccount: UntisAccount = WatchConnectivityStore.default.accounts.first(where: { $0.primary }) else {
            return nil;
        }
        return primaryAccount;
    }
    
    public func getUntisClient() -> UntisClient? {
        if let untisClient: UntisClient = self.untisClient {
            return untisClient;
        }
        guard let primaryAccount: UntisAccount = self.getPrimaryAccount() else {
            return nil;
        }
        let credentials = BasicUntisCredentials(username: primaryAccount.username, password: primaryAccount.password, server: primaryAccount.server, school: primaryAccount.school, authType: primaryAccount.authType);
        self.untisClient = UntisClient(credentials: credentials);
        return self.untisClient;
    }

    public func reloadComplications() {
        let server: CLKComplicationServer = CLKComplicationServer.sharedInstance()
        if server.activeComplications != nil {
            for complication in server.activeComplications! {
                log.debug("Reload complication")
                server.reloadTimeline(for: complication)
            }
        }
        if let disk = getBackgroundTaskDiskStorage() {
            do {
                try disk.setObject(Date(), forKey: "lastComplicationReload", expiry: .seconds(60 * 60))
            } catch (let error) {
                log.error("Can not set lastComplicationReload", context: ["error": error]);
            }
        }
    }
    
    func getBackgroundTaskDiskStorage() -> DiskStorage<String, Date>? {
        if self.backgroundTaskDiskStorage != nil {
            return self.backgroundTaskDiskStorage;
        }
        let diskConfig = DiskConfig(name: "UntisBackgroundTaskStorage", expiry: .never);
        guard let backgroundTaskStorage = try? DiskStorage<String, Date>(config: diskConfig, transformer: TransformerFactory.forCodable(ofType: Date.self)) else {
            return nil;
        }
        self.backgroundTaskDiskStorage = backgroundTaskStorage;
        return self.backgroundTaskDiskStorage;
    }
    
    func shouldReloadComplications() -> Bool {
        guard let disk = getBackgroundTaskDiskStorage() else {
            log.error("Missing background task disk. Reload should reload complication");
            return true;
        }
        
        if let exists = try? disk.existsObject(forKey: "lastComplicationReload") {
            if !exists {
                return true;
            }
        }
        
        if let isExpired = try? disk.isExpiredObject(forKey: "lastComplicationReload") {
            if !isExpired {
                log.debug("lastComplicationReload is not expired. Should not reload complication")
                return false;
            }
        }
        
        return true;
    }
}
