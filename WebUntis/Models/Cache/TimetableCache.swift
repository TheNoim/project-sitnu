//
//  TimetableCache.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import Foundation

struct TimetableCache: Codable {
    let periods: [Period];
    var date: Date = Date();
    
    var expired: Bool { Calendar.current.date(byAdding: .minute, value: 5, to: self.date)! > Date() }
}
