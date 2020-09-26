//
//  BackgroundUtility.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 21/09/2020.
//

import Foundation
import Cache
import ClockKit

class BackgroundUtility {
    public static let shared = BackgroundUtility();
    
    var untisClient: UntisClient?;
    
    public func getContext() -> SharedContext? {
        if let storage = try? DiskStorage(config: DiskConfig(name: "UntisWA", expiry: .never), transformer: TransformerFactory.forCodable(ofType: SharedContext.self)) {
            if let sharedContext: SharedContext = try? storage.object(forKey: "context") {
                return sharedContext;
            }
        }
        return nil;
    }
    
    
    public func getUntisClient() -> UntisClient? {
        if let untisClient: UntisClient = self.untisClient {
            return untisClient;
        }
        guard let sharedContext: SharedContext = self.getContext() else {
            return nil;
        }
        if sharedContext.accounts.count < 1 {
            return nil;
        }
        guard let primaryAccount: UntisAccount = sharedContext.accounts.first(where: { $0.primary }) else {
            return nil;
        }
        let credentials = BasicUntisCredentials(username: primaryAccount.username, password: primaryAccount.password, server: primaryAccount.server, school: primaryAccount.school);
        self.untisClient = UntisClient(credentials: credentials);
        return self.untisClient;
    }

    public func reloadComplications() {
        let server: CLKComplicationServer = CLKComplicationServer.sharedInstance()
        if server.activeComplications != nil {
            for complication in server.activeComplications! {
                server.reloadTimeline(for: complication)
            }
        }
    }
}
