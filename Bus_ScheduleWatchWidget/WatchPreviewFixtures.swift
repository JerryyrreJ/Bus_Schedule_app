//
//  WatchPreviewFixtures.swift
//  Bus_ScheduleWatchWidget
//
//  Shared preview fixtures for watch complications. Centralizing the dates
//  keeps scenario naming consistent across circular, rectangular, inline,
//  and corner previews.
//

import Foundation
import BusScheduleCore

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

enum WatchPreviewFixtures {
    static let circularMorning = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 8, minute: 18),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let circularBeforeFirstDeparture = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 6, minute: 58),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let circularReturnImmediately = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 8, minute: 22),
        primaryRoute: .phIParkingLot,
        dayType: .weekday,
        isManualOverride: false
    )

    static let circularLastBus = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 21, minute: 58),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let circularServiceEnded = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 22, minute: 20),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let rectangularMorning = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 8, minute: 12),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let rectangularReturnImmediately = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 13, minute: 44),
        primaryRoute: .phIParkingLot,
        dayType: .weekday,
        isManualOverride: true
    )

    static let rectangularLastBus = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 22, minute: 2),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let rectangularServiceEnded = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 22, minute: 31),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let inlineMorning = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 8, minute: 12),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let inlineReturnImmediately = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 8, minute: 22),
        primaryRoute: .phIParkingLot,
        dayType: .weekday,
        isManualOverride: false
    )

    static let inlineLastBus = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 10, hour: 22, minute: 52),
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: false
    )

    static let inlineServiceEnded = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 10, hour: 23, minute: 12),
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: false
    )

    static let cornerMorning = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 17, minute: 41),
        primaryRoute: .phIINewCampus,
        dayType: .weekday,
        isManualOverride: false
    )

    static let cornerReturnImmediately = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 6, hour: 13, minute: 44),
        primaryRoute: .phIParkingLot,
        dayType: .weekday,
        isManualOverride: false
    )

    static let cornerLastBus = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 10, hour: 22, minute: 56),
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: false
    )

    static let cornerServiceEnded = ShuttleEntry(
        date: previewDate(year: 2026, month: 5, day: 10, hour: 23, minute: 12),
        primaryRoute: .phIParkingLot,
        dayType: .sundayOrHoliday,
        isManualOverride: false
    )
}
