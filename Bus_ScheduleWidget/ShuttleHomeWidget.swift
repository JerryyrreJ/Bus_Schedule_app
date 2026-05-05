//
//  ShuttleHomeWidget.swift
//  Bus_ScheduleWidget
//
//  Home-screen widget configuration covering both Small and Medium sizes.
//  A single Widget definition; the view dispatches by `family`.
//

import WidgetKit
import SwiftUI

struct ShuttleHomeWidget: Widget {
    let kind: String = "ShuttleHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            ShuttleHomeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(uiColor: .systemBackground)
                }
        }
        .configurationDisplayName("Campus Shuttle")
        .description("Next departure, countdown, and upcoming times.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ShuttleHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ShuttleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
