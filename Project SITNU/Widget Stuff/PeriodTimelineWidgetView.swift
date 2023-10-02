//
//  PeriodTimlineWidgetView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2023.
//

import SwiftUI
import WidgetKit

struct PeriodTimlineWidgetView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    let entry: PeriodWidgetTimelineEntry
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall: PeriodTimlineWidgetSmall(entry: entry)
        default: PeriodTimlineWidgetNotAvailable()
        }
    }
}

struct PeriodTimlineWidgetNotAvailable: View {
    var body: some View {
        Text("Not available")
    }
}

//#Preview {
//    PeriodTimlineWidgetView()
//}
