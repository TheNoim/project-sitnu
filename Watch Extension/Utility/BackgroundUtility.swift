//
//  BackgroundUtility.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 21/09/2020.
//

import Foundation
import Cache

class BackgroundUtility {
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
        if let untisClient = self.untisClient {
            return untisClient;
        }
        guard let sharedContext = self.getContext() else {
            return nil;
        }
        if sharedContext.accounts.count < 1 {
            return nil;
        }
        guard let primaryAccount = sharedContext.accounts.first(where: { $0.primary }) else {
            return nil;
        }
        let credentials = BasicUntisCredentials(username: primaryAccount.username, password: primaryAccount.password, server: primaryAccount.server, school: primaryAccount.school);
        self.untisClient = UntisClient(credentials: credentials);
        return self.untisClient;
    }
}
