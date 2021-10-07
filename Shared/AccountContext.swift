//
//  AccountContext.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import Foundation

struct SharedContext: Codable {
    let accounts: [UntisAccount];
}

struct UntisAccount: Codable, Identifiable {
    let id: UUID;
    let username: String;
    let password: String;
    let server: String;
    let school: String;
    let setDisplayName: String?;
    let authType: AuthType;
    var primary: Bool;
    var preferShortRoom: Bool = false;
    var preferShortSubject: Bool = false;
    var preferShortTeacher: Bool = false;
    var preferShortClass: Bool = false;
    
    var displayName: String {
        if self.setDisplayName != nil {
            return self.setDisplayName!;
        } else {
            return "\(self.username) @ \(self.school)"
        }
    }
    
    func copy() -> UntisAccount {
        let copy = UntisAccount(id: id, username: username, password: password, server: server, school: school, setDisplayName: setDisplayName, authType: authType, primary: primary, preferShortRoom: preferShortRoom, preferShortSubject: preferShortSubject, preferShortTeacher: preferShortTeacher, preferShortClass: preferShortClass);
        return copy;
    }
}
