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

class HostingController: WKHostingController<AnyView> {
    @State private var watchConnectivityStore = WatchConnectivityStore.default
    
    let contentView = ContentView();
    
    override var body: AnyView {
        return AnyView(self.contentView.environment(self.watchConnectivityStore))
    }
    
    override func willActivate() {
        super.willActivate();
        
        watchConnectivityStore.initialize()
    }
}
