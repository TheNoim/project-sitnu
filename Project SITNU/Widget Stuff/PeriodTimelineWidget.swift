//
//  PeriodTimelineWidget.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2023.
//

import Foundation
import SwiftUI
import WidgetKit

struct PeriodTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "io.noim.Project-SITNU.widgets.timeline",
            provider: PeriodTimelineProvider()
        ) { entry in
            PeriodTimlineWidgetView(entry: entry)
        }
        .configurationDisplayName("Game Status")
        .description("Shows an overview of your game status")
        .supportedFamilies([.systemSmall])
    }
}
