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
    @Published var useSecretLogin: Bool = false;
    
    var authType: AuthType {
        if useSecretLogin {
            return .SECRET
        }
        return .PASSWORD;
    };
    @Published var setDisplayName: String = "";
    @Published var primary: Bool = false;
    @Published var preferShortRoom: Bool = false;
    @Published var preferShortSubject: Bool = false;
    @Published var preferShortTeacher: Bool = false;
    @Published var preferShortClass: Bool = false;
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
    
    init(school: School) {
        self.school = school;
        self.acc.useSecretLogin = school.useSecret;
        if !school.user.isEmpty {
            self.acc.username = school.user;
        }
        if !school.password.isEmpty {
            self.acc.password = school.password;
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Server & School")) {
                TextField("Server", text: self.$school.server)
                TextField("School", text: self.$school.loginName)
            }
            Section(header: Text("Settings")) {
                TextField("Displayname (Optional)", text: self.$acc.setDisplayName)
                if !self.needsToBePrimary() {
                    Toggle(isOn: self.$acc.primary) {
                        Text("Add as Primary")
                    }.disabled(testing)
                }
                Text("Prefer the short representation of: ")
                Toggle("Rooms", isOn: self.$acc.preferShortRoom)
                Toggle("Teachers", isOn: self.$acc.preferShortTeacher)
                Toggle("Subjects", isOn: self.$acc.preferShortSubject)
                // Toggle("Classes", isOn: self.$acc.preferShortClass) // Currently not in use
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
                Toggle("Use secret", isOn: self.$acc.useSecretLogin)
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
        self.basicCredentials = BasicUntisCredentials(username: self.acc.username, password: self.acc.password, server: self.school.server, school: self.school.loginName.replacingOccurrences(of: " ", with: "+").components(separatedBy: "+").map({ $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! }).joined(separator: "+"), authType: self.acc.authType);
        
        print(self.basicCredentials)
        self.untis = UntisClient(credentials: self.basicCredentials!);
        self.untis!.getLatestImportTime(force: true, cachedHandler: nil) { result in
            self.handleUntisResponse(result: result);
        }
    }
    
    func handleUntisResponse(result: Swift.Result<Int64, Error>) {
        switch result {
        case .success:
            let id = UUID();
            let primary = self.needsToBePrimary() || self.acc.primary;
            let setDisplayName: String? = self.acc.setDisplayName.isEmpty ? nil : self.acc.setDisplayName;
            let acc = UntisAccount(id: id, username: self.acc.username, password: self.acc.password, server: self.school.server, school: self.school.loginName.replacingOccurrences(of: " ", with: "+").components(separatedBy: "+").map({ $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! }).joined(separator: "+"), setDisplayName: setDisplayName, authType: self.acc.authType, primary: primary, preferShortRoom: self.acc.preferShortRoom, preferShortSubject: self.acc.preferShortSubject, preferShortTeacher: self.acc.preferShortTeacher, preferShortClass: self.acc.preferShortClass);
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
