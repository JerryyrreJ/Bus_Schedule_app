//
//  ShuttleComplications.swift
//  Bus_ScheduleWatchWidget
//
//  Four watchOS complication configurations. All share the same Provider from
//  BusScheduleCore — they differ only in family + view.
//

import WidgetKit
import SwiftUI
import BusScheduleCore

struct ShuttleWatchCircular: Widget {
    let kind = "ShuttleWatchCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            WatchCircularView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Shuttle · Circular")
        .description("Bus icon and next departure.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ShuttleWatchRectangular: Widget {
    let kind = "ShuttleWatchRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchRectangularView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Shuttle · Rectangular")
        .description("Route, time, and countdown.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct ShuttleWatchInline: Widget {
    let kind = "ShuttleWatchInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchInlineView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Shuttle · Inline")
        .description("Single-line summary alongside the time.")
        .supportedFamilies([.accessoryInline])
    }
}

struct ShuttleWatchCorner: Widget {
    let kind = "ShuttleWatchCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            WatchCornerView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Shuttle · Corner")
        .description("Corner of the Infograph face.")
        .supportedFamilies([.accessoryCorner])
    }
}
