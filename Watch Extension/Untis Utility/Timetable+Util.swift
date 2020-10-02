//
//  Timetable+displayName.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import Foundation

extension Period.SubType {
    
    var displayName: String {
        if let longname = longname {
            return longname;
        } else if let name = name {
            return name;
        } else {
            if let formattedInt = try? String(from: id) {
                return formattedInt;
            } else {
                return "";
            }
        }
    }
    
    var shortDisplayName: String {
        if let name = name {
            return name;
        } else {
            if let formattedInt = try? String(from: id) {
                return formattedInt;
            } else {
                return "";
            }
        }
    }
    
}

extension Array where Element == Period {
    
    func sortedPeriods(useEndtime: Bool = false) -> [Period] {
        if useEndtime {
            return self.sorted { (a, b) -> Bool in
                return a.endTime < b.endTime
            }
        } else {
            return self.sorted { (a, b) -> Bool in
                return a.startTime < b.startTime
            }
        }
    }
    
}
