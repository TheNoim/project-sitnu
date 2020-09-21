//
//  Timegrid.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation

struct TimegridCache: Codable {
    let timegrid: Timegrid;
    var date: Date = Date();
    
    var expired: Bool { Calendar.current.date(byAdding: .day, value: 1, to: self.date)! > Date() }
}
