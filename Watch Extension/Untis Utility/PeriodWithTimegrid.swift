//
//  PeriodWithTimegrid.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import Foundation

struct PeriodWithUnit: Codable {
    let period: Period;
    let startUnit: UnitInformation?;
    let endUnit: UnitInformation?;
    
    var oneUnit: Bool {
        guard let startUnit = startUnit else {
            return false;
        }
        guard let endUnit = endUnit else {
            return false;
        }
        return endUnit == startUnit;
    }
    
    var combinedUnit: UnitInformation? {
        if startUnit == nil && endUnit == nil {
            return nil;
        }
        if startUnit != nil && endUnit != nil {
            if self.oneUnit {
                let timeunit = Timeunit(name: startUnit!.unit.name, startTime: startUnit!.unit.startTime, endTime: endUnit!.unit.startTime);
                return UnitInformation(day: startUnit!.day, unit: timeunit);
            } else {
                let timeunit = Timeunit(name: "\(startUnit!.unit.name)-\(endUnit!.unit.name)", startTime: startUnit!.unit.startTime, endTime: endUnit!.unit.startTime);
                return UnitInformation(day: startUnit!.day, unit: timeunit);
            }
        }
        if startUnit != nil && endUnit == nil {
            let timeunit = Timeunit(name: startUnit!.unit.name, startTime: startUnit!.unit.startTime, endTime: startUnit!.unit.startTime);
            return UnitInformation(day: startUnit!.day, unit: timeunit);
        }
        if startUnit == nil && endUnit != nil {
            let timeunit = Timeunit(name: endUnit!.unit.name, startTime: endUnit!.unit.startTime, endTime: endUnit!.unit.startTime);
            return UnitInformation(day: endUnit!.day, unit: timeunit);
        }
        return nil;
    }
}

struct UnitInformation: Codable, Equatable {
    static func == (lhs: UnitInformation, rhs: UnitInformation) -> Bool {
        return
            lhs.day.rawValue == rhs.day.rawValue &&
            lhs.unit.name == rhs.unit.name &&
            lhs.unit.startTime == rhs.unit.startTime &&
            lhs.unit.endTime == rhs.unit.endTime;
    }
    
    let day: TimegridEntry.Day;
    let unit: Timeunit;
}
