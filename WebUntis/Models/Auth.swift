//
//  Auth.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation
import Alamofire

struct BasicUntisCredentials: Codable {
    let username: String;
    let password: String;
    let server: String;
    let school: String;
}

struct UntisCredentials: AuthenticationCredential {
    /**
     Required for authentication
     */
    let username: String;
    let password: String;
    let server: String;
    let school: String;
    
    /**
     Optional
     */
    var session: String?;
    var issuedAt: Date?;
    
    /**
     Session based
     */
    var type: Int?;
    var id: Int?;
    
    /**
     Session expires after 15 minutes
     */
    var requiresRefresh: Bool {
        if issuedAt == nil {
            return true;
        }
        if session == nil {
            return true;
        }
        if type == nil {
            return true;
        }
        if id == nil {
            return true;
        }
        guard let expires = Calendar.current.date(byAdding: .minute, value: 15, to: issuedAt!) else {
            return true;
        }
        if expires > Date() {
            return false;
        }
        return true;
    }
}
