//
//  ContentView.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 19/09/2020.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var accountStore: AccountStore;
    @State var isAccountChanger: Bool = false;
    
    var body: some View {
        if !self.accountStore.initialFetch {
            ActivityIndicator(active: true)
        } else {
            if self.accountStore.selected != nil {
                let acc = self.accountStore.selected!;
                ScrollView {
                    TimetableView(account: acc)
                    Divider()
                    Button("Change account") {
                        self.isAccountChanger.toggle();
                    }
                        .foregroundColor(.yellow)
                    .sheet(isPresented: $isAccountChanger, content: { AccountSelector(isOpen: $isAccountChanger).environmentObject(self.accountStore) })
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
