//
//  ImportTime.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation

struct ImportTimeCache: Codable {
    let time: Int;
    var date: Date = Date();
    
    var expired: Bool { Calendar.current.date(byAdding: .minute, value: 5, to: self.date)! > Date() }
}
