//
//  SubjectsCache.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import Foundation

struct SubjectsCache: Codable {
    let subjects: [Subject];
    var date: Date = Date();
    
    var expired: Bool { Calendar.current.date(byAdding: .day, value: 2, to: self.date)! > Date() }
}
