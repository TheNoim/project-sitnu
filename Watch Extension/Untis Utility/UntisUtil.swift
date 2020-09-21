//
//  UntisFormatter.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import Foundation
import SwiftUI

class UntisUtil {
    static let `default`: UntisUtil = UntisUtil();
    
    func getPeriodWithUnit(period: Period, timegrid: Timegrid?) -> PeriodWithUnit {
        let without: PeriodWithUnit = PeriodWithUnit(period: period, startUnit: nil, endUnit: nil);
        guard let timegrid = timegrid else {
            return without;
        }
        let date = period.date;
        let dayIndex = timegrid.days.firstIndex(where: {
            return $0.day.rawValue == Calendar.current.component(.weekday, from: date);
        });
        if dayIndex == nil {
            return without;
        }
        let day = timegrid.days[dayIndex!];
        let units = day.timeUnits;
        let startUnit = units.first(where: { $0.startTime == period.untisStartTime });
        let endUnit = units.first(where: { $0.endTime == period.untisEndTime });
        var startUnitInfo: UnitInformation?;
        var endUnitInfo: UnitInformation?;
        if startUnit != nil {
            startUnitInfo = UnitInformation(day: day.day, unit: startUnit!);
        }
        if endUnit != nil {
            endUnitInfo = UnitInformation(day: day.day, unit: endUnit!);
        }
    
        return PeriodWithUnit(period: period, startUnit: startUnitInfo, endUnit: endUnitInfo);
    }
    
    func getRowTitle(period: Period, timegrid: Timegrid?) -> String {
        let periodWithUnit = self.getPeriodWithUnit(period: period, timegrid: timegrid);
        let subjectList = ListFormatter.localizedString(byJoining: period.subjects.map({ $0.displayName }));
        if periodWithUnit.combinedUnit == nil {
            return subjectList;
        } else {
            return "\(periodWithUnit.combinedUnit!.unit.name) \(subjectList)";
        }
    }
    
    func getColor(for period: Period, subjects: [Subject]?) -> Color {
        if subjects == nil {
            return .white;
        }
        for subject in period.subjects {
            if let subject = subjects!.first(where: { $0.id == subject.id }) {
                return Color(hex: subject.backColor);
            }
        }
        return .white;
    }
    
    func getSubtypeListString(subTypes: [Period.SubType]) -> String {
        let subTypeNames = subTypes.map({ $0.displayName });
        if subTypeNames.count < 1 {
            return "-";
        }
        let formatter = ListFormatter();
        return formatter.string(for: subTypeNames)!;
    }
    
    func getRowSubtitle(period: Period) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "\(formatter.string(from: period.startTime))-\(formatter.string(from: period.endTime))";
    }
    
//    func getRowTitle(period: Period, timegrid: Timegrid?) -> String {
//        let date = period.date;
//        if timegrid != nil {
//            let dayIndex = timegrid?.days.firstIndex(where: {
//                return $0.day.rawValue == Calendar.current.component(.weekday, from: date);
//            });
//            if dayIndex != nil {
//                if let units = timegrid?.days[dayIndex!].timeUnits {
//
//                }
//            }
//        }
//        return ListFormatter.localizedString(byJoining: period.subjects.map({
//            if let longname = $0.longname {
//                return longname;
//            } else if let name = $0.name {
//                return name;
//            } else {
//                if let formattedInt = try? String(from: $0.id) {
//                    return formattedInt;
//                } else {
//                    return "";
//                }
//            }
//        }))
//    }
}
