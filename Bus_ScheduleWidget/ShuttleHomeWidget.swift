//
//  ShuttleHomeWidget.swift
//  Bus_ScheduleWidget
//
//  Home-screen widget configuration covering both Small and Medium sizes.
//  Backed by AppIntentConfiguration so users can pick a visual style
//  (card or minimal) per widget instance.
//

import WidgetKit
import SwiftUI
import BusScheduleCore

struct ShuttleHomeWidget: Widget {
    let kind: String = "ShuttleHomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ShuttleHomeIntent.self,
            provider: IntentShuttleProvider()
        ) { entry in
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
    let entry: StyledShuttleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry.base)
        case .systemMedium:
            MediumWidgetView(entry: entry.base, style: entry.style)
        default:
            SmallWidgetView(entry: entry.base)
        }
    }
}

private func previewDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int
) -> Date {
    Calendar.current.date(
        from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
    ) ?? .now
}

private func previewEntry(
    date: Date,
    primaryRoute: Location,
    dayType: DayType,
    isManualOverride: Bool,
    style: WidgetStyle = .card
) -> StyledShuttleEntry {
    StyledShuttleEntry(
        base: ShuttleEntry(
            date: date,
            primaryRoute: primaryRoute,
            dayType: dayType,
            isManualOverride: isManualOverride
        ),
        style: style
    )
}

#Preview("Small · Morning", as: .systemSmall) {
    ShuttleHomeWidget()
} timeline: {
    previewEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 8, minute: 12),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )
}

#Preview("Small · Service Ended", as: .systemSmall) {
    ShuttleHomeWidget()
} timeline: {
    previewEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 22, minute: 12),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )
}

#Preview("Medium · Card · Afternoon", as: .systemMedium) {
    ShuttleHomeWidget()
} timeline: {
    previewEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 17, minute: 38),
        primaryRoute: .phIParkingLot,
        dayType: .weekday,
        isManualOverride: true,
        style: .card
    )
}

#Preview("Medium · Card · Service Ended", as: .systemMedium) {
    ShuttleHomeWidget()
} timeline: {
    previewEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 22, minute: 31),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false,
        style: .card
    )
}

#Preview("Medium · Minimal · Afternoon", as: .systemMedium) {
    ShuttleHomeWidget()
} timeline: {
    previewEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 17, minute: 38),
        primaryRoute: .phIParkingLot,
        dayType: .weekday,
        isManualOverride: true,
        style: .minimal
    )
}

#Preview("Medium · Minimal · Service Ended", as: .systemMedium) {
    ShuttleHomeWidget()
} timeline: {
    previewEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 22, minute: 31),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false,
        style: .minimal
    )
}
