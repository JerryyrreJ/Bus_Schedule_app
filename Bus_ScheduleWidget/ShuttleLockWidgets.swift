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
