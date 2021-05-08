//
//  HostingController.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 19/09/2020.
//

import WatchKit
import Foundation
import SwiftUI
import WatchConnectivity
import Cache

class HostingController: WKHostingController<AnyView>, WCSessionDelegate {
    var activated: Bool = false;
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context: [String: Any] = session.receivedApplicationContext;
        self.setContext(context);
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        self.setContext(applicationContext);
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let action: String = message["action"] as? String else {
            log.error("Failed to decode WCSession message", context: ["message": message]);
            return;
        }
        log.info("Received action", context: ["action": action]);
        if action == "copyLogs" {
            guard let delegate: ExtensionDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
                log.error("Missing Extension delegate");
                return;
            }
            guard let logLocation: URL = delegate.logLocation else {
                log.error("Missing log location");
                return;
            }
            if !FileManager.default.fileExists(atPath: logLocation.relativePath) {
                log.error("Log file doesn't exist");
                return;
            }
            let logDirectory: URL = logLocation.deletingLastPathComponent();
            let copyDate: Date = Date();
            let copyLogLocation: URL = logDirectory.appendingPathComponent("sitnu-\(copyDate.timeIntervalSince1970).log", isDirectory: false);
            try? FileManager.default.copyItem(at: logLocation, to: copyLogLocation);
            if !FileManager.default.fileExists(atPath: copyLogLocation.relativePath) {
                log.error("Failed to duplicate log file");
                return;
            }
            log.info("Start log transfer", context: ["location": copyLogLocation.absoluteURL]);
            session.transferFile(copyLogLocation, metadata: ["date": copyDate, "type": "log"]);
        }
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error = error {
            log.error("File transfer finished with an error", context: ["error": error]);
            return
        }
        log.info("File transfer finished successfully");
    }
    
    @ObservedObject var accountStore: AccountStore = AccountStore();
    
    let contentView = ContentView();
    
    override var body: AnyView {
        return AnyView(self.contentView.environmentObject(self.accountStore))
    }
    
    override func willActivate() {
        super.willActivate();
        
        WCSession.default.delegate = self;
        
        if WCSession.isSupported() && self.activated == false {
            self.activated = true;
            WCSession.default.activate();
        }
    }
    
    func setContext(_ context: [String: Any]) {
        if let sharedContext: SharedContext = try? SharedContext(from: context) {
            DispatchQueue.main.async {
                do {
                    let storage = try DiskStorage<String, SharedContext>(config: DiskConfig(name: "UntisWA", expiry: .never), transformer: TransformerFactory.forCodable(ofType: SharedContext.self));
                    try storage.setObject(sharedContext, forKey: "context");
                } catch {
                    print(error)
                }
                self.accountStore.accounts = sharedContext.accounts;
                if self.accountStore.accounts.count > 0 {
                    if let firstPrimaryIndex: Int = self.accountStore.accounts.firstIndex(where: { $0.primary }) {
                        self.accountStore.selected = self.accountStore.accounts[firstPrimaryIndex];
                    } else {
                        self.accountStore.selected = nil;
                    }
                } else {
                    self.accountStore.selected = nil;
                }
                self.accountStore.initialFetch = true;
            }
        }
    }
}
