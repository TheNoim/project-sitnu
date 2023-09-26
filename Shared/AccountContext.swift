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
    let id: UUID
    let username: String
    let password: String
    let server: String
    let school: String
    let setDisplayName: String?
    let authType: AuthType
    var primary: Bool
    var preferShortRoom: Bool = false
    var preferShortSubject: Bool = false
    var preferShortTeacher: Bool = false
    var preferShortClass: Bool = false
    
    var displayName: String {
        if let setDisplayName = setDisplayName {
            return setDisplayName
        } else {
            return "\(username) @ \(school)"
        }
    }
    
    init(id: UUID, username: String, password: String, server: String, school: String, setDisplayName: String?, authType: AuthType, primary: Bool, preferShortRoom: Bool, preferShortSubject: Bool, preferShortTeacher: Bool, preferShortClass: Bool) {
        self.id = id
        self.username = username
        self.password = password
        self.server = server
        self.school = school
        self.setDisplayName = setDisplayName
        self.authType = authType
        self.primary = primary
        self.preferShortRoom = preferShortRoom
        self.preferShortSubject = preferShortSubject
        self.preferShortTeacher = preferShortTeacher
        self.preferShortClass = preferShortClass
    }
    
    // MARK: - Codable Implementations
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case password
        case server
        case school
        case setDisplayName
        case authType
        case primary
        case preferShortRoom
        case preferShortSubject
        case preferShortTeacher
        case preferShortClass
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        server = try container.decode(String.self, forKey: .server)
        school = try container.decode(String.self, forKey: .school)
        setDisplayName = try container.decodeIfPresent(String.self, forKey: .setDisplayName)
        authType = try container.decode(AuthType.self, forKey: .authType)
        primary = try container.decode(Bool.self, forKey: .primary)
        preferShortRoom = try container.decode(Bool.self, forKey: .preferShortRoom)
        preferShortSubject = try container.decode(Bool.self, forKey: .preferShortSubject)
        preferShortTeacher = try container.decode(Bool.self, forKey: .preferShortTeacher)
        preferShortClass = try container.decode(Bool.self, forKey: .preferShortClass)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(server, forKey: .server)
        try container.encode(school, forKey: .school)
        if setDisplayName != nil {
            try container.encode(setDisplayName, forKey: .setDisplayName)
        }
        try container.encode(authType, forKey: .authType)
        try container.encode(primary, forKey: .primary)
        try container.encode(preferShortRoom, forKey: .preferShortRoom)
        try container.encode(preferShortSubject, forKey: .preferShortSubject)
        try container.encode(preferShortTeacher, forKey: .preferShortTeacher)
        try container.encode(preferShortClass, forKey: .preferShortClass)
    }
}
