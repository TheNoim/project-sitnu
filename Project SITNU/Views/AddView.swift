//
//  AddView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import SwiftUI

class UntisAccountStore: ObservableObject {
    @Published var username: String = "";
    @Published var password: String = "";
    @Published var setDisplayName: String = "";
    @Published var primary: Bool = false;
}

struct AddView: View {
    @State var school: School;
    @State var acc: UntisAccountStore = UntisAccountStore()
    @State var testing: Bool = false;
    @State var error: String?;
    @State var untis: UntisClient?;
    @State var basicCredentials: BasicUntisCredentials?;
    @EnvironmentObject var store: WatchStore
    @EnvironmentObject var addNavigationController: AddNavigationController;
    
    var body: some View {
        Form {
            Section(header: Text("Server & School")) {
                TextField("Server", text: .constant(self.school.server)).disabled(true)
                TextField("School", text: .constant(self.school.loginName)).disabled(true)
            }
            Section(header: Text("Settings")) {
                TextField("Displayname (Optional)", text: self.$acc.setDisplayName)
                if !self.needsToBePrimary() {
                    Toggle(isOn: self.$acc.primary) {
                        Text("Add as Primary")
                    }.disabled(testing)
                }
            }
            Section(header: Text("Login")) {
                TextField("Username", text: self.$acc.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(testing)
                SecureField("Password", text: self.$acc.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(testing)
                if self.error != nil {
                    Text(self.error!)
                        .foregroundColor(.red)
                }
                Button("Test login and add", action: { self.testLoginAndAdd() })
                    .disabled(testing)
            }
        }
        .navigationBarTitle(self.school.displayName)
    }
    
    func needsToBePrimary() -> Bool {
        if self.store.accounts.count < 1 {
            return true;
        }
        for acc in self.store.accounts {
            if acc.primary {
                return false
            }
        }
        return true;
    }
    
    func testLoginAndAdd() {
        if self.testing {
            return;
        }
        withAnimation {
            self.error = nil;
            self.testing = true;
        }
        self.untis = nil;
        self.basicCredentials = nil;
        self.basicCredentials = BasicUntisCredentials(username: self.acc.username, password: self.acc.password, server: self.school.server, school: self.school.loginName);
        self.untis = UntisClient(credentials: self.basicCredentials!);
        self.untis!.getLatestImportTime(force: true, cachedHandler: nil) { result in
            self.handleUntisResponse(result: result);
        }
    }
    
    func handleUntisResponse(result: Swift.Result<Int, Error>) {
        switch result {
        case .success:
            let id = UUID();
            let primary = self.needsToBePrimary() || self.acc.primary;
            let setDisplayName: String? = self.acc.setDisplayName.isEmpty ? nil : self.acc.setDisplayName;
            let acc = UntisAccount(id: id, username: self.acc.username, password: self.acc.password, server: self.school.server, school: self.school.loginName, setDisplayName: setDisplayName, primary: primary);
            if primary {
                for (index, _) in self.store.accounts.enumerated() {
                    if self.store.accounts[index].primary {
                        self.store.accounts[index].primary = false;
                    }
                }
            }
            self.store.accounts.append(acc);
            self.store.sync();
            self.addNavigationController.addsAccount = false;
            break;
        case .failure(let error):
            print("Error: \(error.localizedDescription)")
            withAnimation {
                self.error = error.localizedDescription;
            }
            break;
        }
        withAnimation {
            self.testing = false;
        }
    }
}

struct AddView_Previews: PreviewProvider {
    static let testSchool = School(server: "mese.webuntis.com", displayName: "MESE", loginName: "mese", schoolId: 1, address: "Whatever")
    
    static var previews: some View {
        AddView(school: testSchool)
    }
}
