//
//  ShuttleLockWidgets.swift
//  Bus_ScheduleWidget
//
//  Three lock-screen accessory widgets (iOS 16+):
//    • accessoryCircular   — bus icon + departure time
//    • accessoryRectangular — route, time, countdown, one follow-up
//    • accessoryInline     — single line with route + time + countdown
//

import WidgetKit
import SwiftUI
import BusScheduleCore

// MARK: - Rectangular (the recommended default)

struct ShuttleLockRectangularWidget: Widget {
    let kind: String = "ShuttleLockRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            LockRectangularView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Shuttle · Rectangular")
        .description("Lock-screen widget with route, departure time, and countdown.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Circular

struct ShuttleLockCircularWidget: Widget {
    let kind: String = "ShuttleLockCircularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            LockCircularView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Shuttle · Circular")
        .description("Compact bus icon and departure time.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Inline

struct ShuttleLockInlineWidget: Widget {
    let kind: String = "ShuttleLockInlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            LockInlineView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Shuttle · Inline")
        .description("Single-line departure summary next to the time.")
        .supportedFamilies([.accessoryInline])
    }
}

#Preview(as: .accessoryRectangular) {
    ShuttleLockRectangularWidget()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 6, hour: 9, minute: 5)) ?? .now,
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )
}

#Preview(as: .accessoryCircular) {
    ShuttleLockCircularWidget()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 10, minute: 34)) ?? .now,
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: true
    )
}

#Preview(as: .accessoryInline) {
    ShuttleLockInlineWidget()
} timeline: {
    ShuttleEntry(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 20, minute: 52)) ?? .now,
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: false
    )
}
