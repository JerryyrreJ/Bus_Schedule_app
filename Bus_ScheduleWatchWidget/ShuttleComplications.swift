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

#Preview(as: .accessoryCircular) {
    ShuttleWatchCircular()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 6, hour: 8, minute: 18)) ?? .now,
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )
}

#Preview(as: .accessoryRectangular) {
    ShuttleWatchRectangular()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 14, minute: 6)) ?? .now,
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: true
    )
}

#Preview(as: .accessoryInline) {
    ShuttleWatchInline()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 21, minute: 12)) ?? .now,
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: false
    )
}

#Preview(as: .accessoryCorner) {
    ShuttleWatchCorner()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 6, hour: 17, minute: 41)) ?? .now,
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )
}
