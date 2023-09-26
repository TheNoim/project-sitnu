//
//  Message.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 25/09/2023.
//

import Foundation

enum MessageType: String, Codable {
    case credentialsSync
    case requestLogFile
}

enum MessageContainer: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case type
        case accounts
    }
    
    static func ==(lhs: MessageContainer, rhs: MessageContainer) -> Bool {
        switch (lhs, rhs) {
        case (.credentialsSync(_), .credentialsSync(_)):
            return true
        case (.requestLogFile, .requestLogFile):
            return true
        default:
            return false
        }
    }
    
    case credentialsSync([UntisAccount])
    case requestLogFile
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(MessageType.self, forKey: .type)
        switch type {
        case .credentialsSync:
            let accounts = try container.decode([UntisAccount].self, forKey: .accounts)
            self = .credentialsSync(accounts)
        case .requestLogFile:
            self = .requestLogFile
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .credentialsSync(let accounts):
            try container.encode(MessageType.credentialsSync, forKey: .type)
            try container.encode(accounts, forKey: .accounts)
        case .requestLogFile:
            try container.encode(MessageType.requestLogFile, forKey: .type)
        }
    }
}
