//
//  AccountView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2020.
//

import SwiftUI

class AddNavigationController: ObservableObject {
    @Published var addsAccount: Bool = false;
}

struct AccountView: View {
    @Environment(WatchConnectivityStore.self) var store
    @ObservedObject var addNavigationController: AddNavigationController = AddNavigationController();
    
    @State private var editMode = EditMode.inactive
    let throttler = Throttler(minimumDelay: 1.0)
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(self.store.accounts) { (acc: UntisAccount) in
                        if acc.primary {
                            Text("\(acc.displayName) (Primary)")
                        } else {
                            Text(acc.displayName)
                        }
                    }
                    .onDelete { (index) in
                        self.store.accounts.remove(atOffsets: index);
                        if self.store.accounts.firstIndex(where: { $0.primary }) == nil && self.store.accounts.count > 0 {
                            self.store.accounts[0].primary = true;
                        }
                        self.store.sync();
                    }
                }
                .if(store.isReachable, transform: { view in
                    view.refreshable {
                        store.sync()
                    }
                })
                .modifier(GroupedListModifier())
                .environment(\.editMode, $editMode)
                .navigationBarItems(leading: Button(action: {
                    withAnimation {
                        if self.editMode == .inactive {
                            self.editMode = .active;
                        } else {
                            self.editMode = .inactive;
                        }
                    }
                }) {
                    Text("Edit")
                        .frame(height: 44)
                }, trailing: self.addButton)
            }
            .navigationBarTitle("WebUntis Accounts")
        }
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(
                Button(action: {
                    self.addNavigationController.addsAccount = true;
                }) {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }.disabled(!store.isReachable).sheet(isPresented: self.$addNavigationController.addsAccount) {
                    SchoolSearchView()
                        .environmentObject(self.addNavigationController)
                        .environment(self.store)
                }
            )
        default:
            return AnyView(EmptyView())
        }
    }
}

struct GroupedListModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 14, *) {
                AnyView(
                    content
                        .listStyle(InsetGroupedListStyle())
                )
            } else {
                content
                    .listStyle(GroupedListStyle())
                    .environment(\.horizontalSizeClass, .regular)
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
