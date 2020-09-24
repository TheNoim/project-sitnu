//
//  DateOffset.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 24/09/2020.
//

import Foundation

struct OffsetCalc {
    let value: Int;
    let com: Calendar.Component;
}

let timeOffsetCalculations: [OffsetCalc] = [
    //OffsetCalc(value: -2, com: .day),
    //OffsetCalc(value: 1, com: .hour)
    // OffsetCalc(value: 2, com: .hour),
    // OffsetCalc(value: 18, com: .minute)
]

func getDateWithOffset(for date: Date, startOfDay: Bool = false) -> Date {
    if timeOffsetCalculations.count > 0 {
        var targetDate = date;
        for calc in timeOffsetCalculations {
            targetDate = Calendar.current.date(byAdding: calc.com, value: calc.value, to: targetDate)!;
        }
        return targetDate;
    } else {
        return date;
    }
}

func getFetchDate(date: Date = Date()) -> Date {
    return getDateWithOffset(for: date, startOfDay: true);
}
