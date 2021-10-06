//
//  AuthSession.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation

struct AuthSession: Codable {
    /**
     Required for authentication
     */
    let username: String;
    let password: String;
    let server: String;
    let school: String;
    let authType: AuthType;
    
    
    /**
     Optional
     */
    var session: String?;
    var issuedAt: Date?;
    var type: Int?;
    var id: Int?;
}
