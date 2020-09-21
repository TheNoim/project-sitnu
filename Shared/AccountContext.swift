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
    var primary: Bool;
    
    var displayName: String {
        if self.setDisplayName != nil {
            return self.setDisplayName!;
        } else {
            return "\(self.username) @ \(self.school)"
        }
    }
}
