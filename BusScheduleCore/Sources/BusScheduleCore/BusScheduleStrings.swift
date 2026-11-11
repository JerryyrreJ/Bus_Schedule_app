//
//  BusScheduleStrings.swift
//  BusScheduleCore
//
//  Shared UI text constants used across the app, widget, and watch targets.
//

import Foundation

public enum BusScheduleStrings {
    public static let returnImmediatelyToken = "Return Immediately"

    public static var campusShuttle: String { localized("Campus Shuttle") }
    public static var homeWidgetDescription: String { localized("Next departure, countdown, and upcoming times.") }
    public static var phaseI: String { localized("Phase I") }
    public static var phaseII: String { localized("Phase II") }
    public static var compactPhaseIToPhaseII: String { localized("Ph I→II") }
    public static var compactPhaseIIToPhaseI: String { localized("Ph II→I") }
    public static var minimalPhaseIToPhaseII: String { localized("1 → 2") }
    public static var minimalPhaseIIToPhaseI: String { localized("2 → 1") }
    public static var weekday: String { localized("Weekday") }
    public static var saturday: String { localized("Saturday") }
    public static var holiday: String { localized("Holiday") }
    public static var sunHoliday: String { localized("Sun/Holiday") }
    public static var manual: String { localized("Manual") }
    public static var auto: String { localized("Auto") }
    public static var nextDeparture: String { localized("Next Departure") }
    public static var nextDepartureLower: String { localized("Next departure") }
    public static var upcoming: String { localized("Upcoming") }
    public static var timeLeft: String { localized("Time Left") }
    public static var departingIn: String { localized("Departing in") }
    public static var leavesIn: String { localized("Leaves in") }
    public static var returnImmediately: String { localized("Return Immediately") }
    public static var returnImmediatelyHelp: String { localized("A bus is continuously available. After dropping off passengers at Phase 1, it returns directly to Phase 2 campus for pickup.") }
    public static var serviceEnded: String { localized("Service ended") }
    public static var serviceEndedToday: String { localized("Service ended today") }
    public static var serviceResumesTomorrow: String { localized("Service resumes tomorrow.") }
    public static var continuousPickupLoopActive: String { localized("Continuous pickup loop is active.") }
    public static var continuousShuttleShort: String { localized("Leaves right away") }
    public static var firstTomorrow: String { localized("FIRST TOMORROW") }
    public static var firstTomorrowLower: String { localized("First tomorrow") }
    public static var then: String { localized("THEN") }
    public static var thenLower: String { localized("then") }
    public static var loop: String { localized("Loop") }
    public static var loopActive: String { localized("Loop active") }
    public static var done: String { localized("Done") }
    public static var noMoreBusesToday: String { localized("No more buses today") }
    public static var noMoreDeparturesAfterThis: String { localized("No more departures after this") }
    public static var lastBusToday: String { localized("Last bus today") }
    public static var unavailable: String { localized("Unavailable") }
    public static var now: String { localized("Now") }
    public static var inPrefix: String { localized("in") }
    public static var untilPrefix: String { localized("Until") }
    public static var untilLowerPrefix: String { localized("until") }
    public static var firstTomorrowPrefix: String { localized("First tomorrow") }
    public static var tmrwPrefix: String { localized("tmrw") }
    public static var untilUpper: String { localized("UNTIL") }
    public static var other: String { localized("Other") }
    public static var last: String { localized("Last") }
    public static var lastTodayWasPrefix: String { localized("Last today was") }
    public static var lastUpper: String { localized("LAST") }
    public static var phaseIToPhaseII: String { localized("Phase I → Phase II") }
    public static var phaseIIToPhaseI: String { localized("Phase II → Phase I") }
    public static var compactHourPlus: String { localized("1H+") }
    public static var shuttleRectangular: String { localized("Shuttle · Rectangular") }
    public static var shuttleCircular: String { localized("Shuttle · Circular") }
    public static var shuttleInline: String { localized("Shuttle · Inline") }
    public static var shuttleCorner: String { localized("Shuttle · Corner") }
    public static var lockRectangularDescription: String { localized("Lock-screen widget with route, departure time, and countdown.") }
    public static var lockCircularDescription: String { localized("Compact bus icon and departure time.") }
    public static var lockInlineDescription: String { localized("Single-line departure summary next to the time.") }
    public static var watchCircularDescription: String { localized("Bus icon and next departure.") }
    public static var watchRectangularDescription: String { localized("Route, time, and countdown.") }
    public static var watchInlineDescription: String { localized("Single-line summary alongside the time.") }
    public static var watchCornerDescription: String { localized("Corner of the Infograph face.") }
    public static var remindThisBus: String { localized("Remind this bus") }
    public static var reminderUnavailable: String { localized("Reminder unavailable") }
    public static var reminderTooClose: String { localized("This bus is too close to set a reminder.") }
    public static var reminderSetPrefix: String { localized("Reminder set") }
    public static var cancelReminder: String { localized("Cancel Reminder") }
    public static var changeReminder: String { localized("Change Reminder") }
    public static var notificationsOff: String { localized("Notifications are off") }
    public static var notificationPermissionMessage: String { localized("Turn on notifications in Settings to get bus reminders.") }
    public static var notificationSchedulingFailed: String { localized("Could not schedule this reminder.") }
    public static var openSettings: String { localized("Open Settings") }
    public static var leavesAt: String { localized("leaves at") }
    public static var minutesLeft: String { localized("minutes left") }
    public static var before: String { localized("before") }

    public static func resource(_ key: StaticString) -> LocalizedStringResource {
        LocalizedStringResource(
            key,
            defaultValue: String.LocalizationValue(String(describing: key)),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func minutes(_ value: Int) -> String {
        "\(value)m"
    }

    public static func reminderLeadOption(_ value: Int) -> String {
        String(
            localized: "\(value) min before",
            bundle: .module
        )
    }

    public static func serviceStartLoop(_ startTime: String) -> String {
        "\(startTime) \(loop)"
    }

    public static func loopActiveUntil(_ deadline: String) -> String {
        "\(loopActive) \(untilLowerPrefix) \(deadline)"
    }

    public static func until(_ deadline: String) -> String {
        "\(untilPrefix) \(deadline)"
    }

    public static func firstTomorrow(_ value: String) -> String {
        "\(firstTomorrowPrefix) \(value)"
    }

    public static func returnImmediatelyMultiline(_ lineBreak: String = "\n") -> String {
        returnImmediately.replacingOccurrences(of: " ", with: lineBreak)
    }

    public static func lastTodayWas(_ value: String) -> String {
        "\(lastTodayWasPrefix) \(value)"
    }

    public static func last(_ value: String) -> String {
        "\(last) \(value)"
    }

    public static func other(_ value: String) -> String {
        "\(other) \(value)"
    }

    public static func reminderSet(_ value: Int) -> String {
        String(
            localized: "Reminder set · \(value)m before",
            bundle: .module
        )
    }

    public static func reminderNotificationBody(route: String, departureTime: String, leadMinutes: Int) -> String {
        String(
            localized: "\(route) leaves at \(departureTime). \(leadMinutes) minutes left.",
            bundle: .module
        )
    }

    private static func localized(_ key: String) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .module
        )
    }
}
