//
//  ContentView.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 19/09/2020.
//

import SwiftUI

struct ContentView: View {
    @Environment(WatchConnectivityStore.self) var watchConnectivityStore
    @State var isAccountChanger: Bool = false;
    
    var body: some View {
        if watchConnectivityStore.accounts.count == 0 {
            ActivityIndicator(active: true)
            Text("Loading accounts...")
            Text("If you haven't added any account yet, you need to add one first on your iPhone")
                .font(.footnote)
                .foregroundColor(.secondary)
        } else {
            if watchConnectivityStore.currentlySelected != nil {
                ScrollView {
                    TimetableView(account: watchConnectivityStore.currentlySelected!)
                    Divider()
                    Button("Change account") {
                        self.isAccountChanger.toggle();
                    }
                        .foregroundColor(.yellow)
                    .sheet(isPresented: $isAccountChanger, content: { AccountSelector(isOpen: $isAccountChanger) })
                }
            } else {
                Text("You need to add at least one primary account");
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
