//
//  Timegrid.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation

struct Timegrid: Codable {
    let days: [TimegridEntry]
}

struct TimegridEntry: Codable {
    let day: Day;
    let timeUnits: [Timeunit];
    
    enum Day: Int, Codable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }
}

struct Timeunit: Codable {
    let name: String;
    let startTime: Int;
    let endTime: Int;
}
