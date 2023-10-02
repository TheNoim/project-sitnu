//
//  PeriodTimlineWidgetSmall.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2023.
//

import SwiftUI
import WidgetKit

struct PeriodTimlineWidgetSmall: View {
    let entry: PeriodWidgetTimelineEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                switch entry.info {
                case .Break(let breakTimelineEntry):
                    Text("Next:")
                        .font(.title)
                    Text(UntisUtil.default.getSubtypeListString(subTypes: breakTimelineEntry.period.subjects))
                        .foregroundStyle(UntisUtil.default.getColor(for: breakTimelineEntry.period, subjects: breakTimelineEntry.subjects))
                    Text(computeSubtitleForBreak(breakTimelineEntry))
                        .lineLimit(2)
                    Text(breakTimelineEntry.date, style: .relative)
                case .Period(let periodTimelineEntry):
                    Text(UntisUtil.default.getRowTitle(acc: periodTimelineEntry.account, period: periodTimelineEntry.period, timegrid: periodTimelineEntry.timegrid))
                        .foregroundStyle(UntisUtil.default.getColor(for: periodTimelineEntry.period, subjects: periodTimelineEntry.subjects))
                        .font(.title)
                    Text(computeSubtitleForBreak(periodTimelineEntry))
                        .lineLimit(2)
                    Text(periodTimelineEntry.period.endTime, style: .relative)
                case .End(_):
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Text("🥳")
                                .font(.largeTitle)
                            Text("The End")
                            Spacer()
                        }
                        Spacer()
                    }
                case .Placeholder:
                    Text("Subject")
                        .foregroundStyle(.blue)
                        .font(.title)
                    Text("In Room by Teacher")
                    Text(WidgetFakeData.getFutureDate(), style: .relative)
                }
                Spacer()
            }
            Spacer()
        }
        .containerBackground(.background, for: .widget)
    }
    
    func computeSubtitleForBreak(_ breakTimelineEntry: PeriodBaseData) -> String {
        var subTitle = "";
        if breakTimelineEntry.period.rooms.count > 0 && breakTimelineEntry.period.teachers.count > 0 {
            subTitle = "In \(UntisUtil.default.getSubtypeListString(subTypes: breakTimelineEntry.period.rooms)) by \(UntisUtil.default.getSubtypeListString(subTypes: breakTimelineEntry.period.teachers))"
        } else if breakTimelineEntry.period.rooms.count > 0 {
            subTitle = "In \(UntisUtil.default.getSubtypeListString(subTypes: breakTimelineEntry.period.rooms))"
        } else if breakTimelineEntry.period.teachers.count > 0 {
            subTitle = "By \(UntisUtil.default.getSubtypeListString(subTypes: breakTimelineEntry.period.teachers))"
        } else {
            subTitle = "-";
        }
        return subTitle
    }
}

#if os(iOS)

#Preview(as: .systemSmall) {
    PeriodTimelineWidget()
} timeline: {
    WidgetFakeData.getWidgetFakeEntry(for: .Break)
    WidgetFakeData.getWidgetFakeEntry(for: .Period)
    WidgetFakeData.getWidgetFakeEntry(for: .End)
    PeriodWidgetTimelineEntry(date: Date(), info: .Placeholder)
}

#endif
