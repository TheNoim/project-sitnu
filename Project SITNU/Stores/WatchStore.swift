//
//  WatchStore.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import Foundation
import Combine

final class WatchStore: ObservableObject {
    @Published var available: Bool = false;
    @Published var canSendMessages: Bool = false;
    @Published var accounts: [UntisAccount] = [];
    @Published var logFiles: [LogFile] = [];
    
    var syncCallback: (([String: Any]) -> Void)?;
    
    func sync() {
        var accounts: [UntisAccount] = [];
        for acc in self.accounts {
            let untisAccount = UntisAccount(id: acc.id, username: acc.username, password: acc.password, server: acc.server, school: acc.school, setDisplayName: acc.setDisplayName, primary: acc.primary);
            accounts.append(untisAccount);
        }
        let context = SharedContext(accounts: accounts);
        if let dict = try? context.asDictionary() {
            if let syncCallback = self.syncCallback {
                syncCallback(dict);
            }
        } else {
            print("Error while encoding context as dictionary");
        }
    }
    
    func updateLogFiles() {
        self.logFiles = LogFileManager.default.loadLogFiles();
    }
}
