//
//  RootView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            AccountView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Accounts")
                }
            AboutView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("About")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
