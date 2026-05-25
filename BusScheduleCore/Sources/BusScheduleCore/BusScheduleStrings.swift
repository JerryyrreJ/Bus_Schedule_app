//
//  BusScheduleStrings.swift
//  BusScheduleCore
//
//  Shared UI text constants used across the app, widget, and watch targets.
//

import Foundation

public enum BusScheduleStrings {
    public static let returnImmediatelyToken = "Return Immediately"

    public static let campusShuttle = localized("Campus Shuttle")
    public static let homeWidgetDescription = localized("Next departure, countdown, and upcoming times.")
    public static let phaseI = localized("Phase I")
    public static let phaseII = localized("Phase II")
    public static let compactPhaseIToPhaseII = localized("Ph I→II")
    public static let compactPhaseIIToPhaseI = localized("Ph II→I")
    public static let minimalPhaseIToPhaseII = localized("1 → 2")
    public static let minimalPhaseIIToPhaseI = localized("2 → 1")
    public static let weekday = localized("Weekday")
    public static let saturday = localized("Saturday")
    public static let holiday = localized("Holiday")
    public static let sunHoliday = localized("Sun/Holiday")
    public static let manual = localized("Manual")
    public static let auto = localized("Auto")
    public static let nextDeparture = localized("Next Departure")
    public static let nextDepartureLower = localized("Next departure")
    public static let upcoming = localized("Upcoming")
    public static let timeLeft = localized("Time Left")
    public static let departingIn = localized("Departing in")
    public static let leavesIn = localized("Leaves in")
    public static let returnImmediately = localized("Return Immediately")
    public static let returnImmediatelyHelp = localized("A bus is continuously available. After dropping off passengers at Phase 1, it returns directly to Phase 2 campus for pickup.")
    public static let serviceEnded = localized("Service ended")
    public static let serviceEndedToday = localized("Service ended today")
    public static let serviceResumesTomorrow = localized("Service resumes tomorrow.")
    public static let continuousPickupLoopActive = localized("Continuous pickup loop is active.")
    public static let firstTomorrow = localized("FIRST TOMORROW")
    public static let firstTomorrowLower = localized("First tomorrow")
    public static let then = localized("THEN")
    public static let thenLower = localized("then")
    public static let loop = localized("Loop")
    public static let loopActive = localized("Loop active")
    public static let done = localized("Done")
    public static let noMoreBusesToday = localized("No more buses today")
    public static let noMoreDeparturesAfterThis = localized("No more departures after this")
    public static let unavailable = localized("Unavailable")
    public static let now = localized("Now")
    public static let inPrefix = localized("in")
    public static let untilPrefix = localized("Until")
    public static let untilLowerPrefix = localized("until")
    public static let firstTomorrowPrefix = localized("First tomorrow")
    public static let tmrwPrefix = localized("tmrw")
    public static let untilUpper = localized("UNTIL")
    public static let other = localized("Other")
    public static let last = localized("Last")
    public static let lastTodayWasPrefix = localized("Last today was")
    public static let lastUpper = localized("LAST")
    public static let phaseIToPhaseII = localized("Phase I → Phase II")
    public static let phaseIIToPhaseI = localized("Phase II → Phase I")
    public static let compactHourPlus = localized("1H+")
    public static let shuttleRectangular = localized("Shuttle · Rectangular")
    public static let shuttleCircular = localized("Shuttle · Circular")
    public static let shuttleInline = localized("Shuttle · Inline")
    public static let shuttleCorner = localized("Shuttle · Corner")
    public static let lockRectangularDescription = localized("Lock-screen widget with route, departure time, and countdown.")
    public static let lockCircularDescription = localized("Compact bus icon and departure time.")
    public static let lockInlineDescription = localized("Single-line departure summary next to the time.")
    public static let watchCircularDescription = localized("Bus icon and next departure.")
    public static let watchRectangularDescription = localized("Route, time, and countdown.")
    public static let watchInlineDescription = localized("Single-line summary alongside the time.")
    public static let watchCornerDescription = localized("Corner of the Infograph face.")
    public static let remindThisBus = localized("Remind this bus")
    public static let reminderUnavailable = localized("Reminder unavailable")
    public static let reminderTooClose = localized("This bus is too close to set a reminder.")
    public static let reminderSetPrefix = localized("Reminder set")
    public static let cancelReminder = localized("Cancel Reminder")
    public static let changeReminder = localized("Change Reminder")
    public static let notificationsOff = localized("Notifications are off")
    public static let notificationPermissionMessage = localized("Turn on notifications in Settings to get bus reminders.")
    public static let notificationSchedulingFailed = localized("Could not schedule this reminder.")
    public static let openSettings = localized("Open Settings")
    public static let leavesAt = localized("leaves at")
    public static let minutesLeft = localized("minutes left")
    public static let before = localized("before")

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

    public static func other(_ value: String) -> String {
        "\(other) \(value)"
    }

    public static func reminderSet(_ value: Int) -> String {
        "\(reminderSetPrefix) \(minutes(value)) \(before)"
    }

    public static func reminderNotificationBody(route: String, departureTime: String, leadMinutes: Int) -> String {
        "\(route) \(leavesAt) \(departureTime). \(leadMinutes) \(minutesLeft)."
    }

    private static func localized(_ key: String) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .module
        )
    }
}
