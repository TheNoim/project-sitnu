//
//  PeriodTimelineEntry.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2023.
//

import Foundation
import WidgetKit

protocol PeriodBaseData {
    var subjects: [Subject] { get }
    var period: Period { get }
}

struct BreakTimelineEntry: PeriodBaseData {
    let date: Date;
    let period: Period
    let timegrid: Timegrid
    let subjects: [Subject]
}

struct PeriodTimelineEntry: PeriodBaseData {
    let account: UntisAccount
    let period: Period
    let timegrid: Timegrid
    let subjects: [Subject]
}

enum PeriodTimelineEntryInfo {
    case Break(BreakTimelineEntry)
    case Period(PeriodTimelineEntry)
    case End(Date)
    case Placeholder
}

struct PeriodWidgetTimelineEntry: TimelineEntry {
    var date: Date
    var info: PeriodTimelineEntryInfo
}
