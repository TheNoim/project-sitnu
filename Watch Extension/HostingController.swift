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
                    let storage = try DiskStorage(config: DiskConfig(name: "UntisWA", expiry: .never), transformer: TransformerFactory.forCodable(ofType: SharedContext.self));
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
