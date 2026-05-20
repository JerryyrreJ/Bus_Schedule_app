//
//  BusScheduleStrings.swift
//  BusScheduleCore
//
//  Shared UI text constants used across the app, widget, and watch targets.
//  This is the first extraction pass before wiring the project to a string
//  catalog.
//

import Foundation

public enum BusScheduleStrings {
    public static let campusShuttle = "Campus Shuttle"
    public static let homeWidgetDescription = "Next departure, countdown, and upcoming times."
    public static let phaseI = "Phase I"
    public static let phaseII = "Phase II"
    public static let compactPhaseIToPhaseII = "Ph I→II"
    public static let compactPhaseIIToPhaseI = "Ph II→I"
    public static let minimalPhaseIToPhaseII = "1 → 2"
    public static let minimalPhaseIIToPhaseI = "2 → 1"
    public static let weekday = "Weekday"
    public static let saturday = "Saturday"
    public static let holiday = "Holiday"
    public static let sunHoliday = "Sun/Holiday"
    public static let manual = "Manual"
    public static let auto = "Auto"
    public static let nextDeparture = "Next Departure"
    public static let nextDepartureLower = "Next departure"
    public static let upcoming = "Upcoming"
    public static let timeLeft = "Time Left"
    public static let departingIn = "Departing in"
    public static let leavesIn = "Leaves in"
    public static let returnImmediately = "Return Immediately"
    public static let returnImmediatelyHelp = "A bus is continuously available. After dropping off passengers at Phase 1, it returns directly to Phase 2 campus for pickup."
    public static let serviceEnded = "Service ended"
    public static let serviceEndedToday = "Service ended today"
    public static let serviceResumesTomorrow = "Service resumes tomorrow."
    public static let continuousPickupLoopActive = "Continuous pickup loop is active."
    public static let firstTomorrow = "FIRST TOMORROW"
    public static let firstTomorrowLower = "First tomorrow"
    public static let then = "THEN"
    public static let thenLower = "then"
    public static let loop = "Loop"
    public static let loopActive = "Loop active"
    public static let done = "Done"
    public static let noMoreBusesToday = "No more buses today"
    public static let noMoreDeparturesAfterThis = "No more departures after this"
    public static let unavailable = "Unavailable"
    public static let now = "Now"
    public static let inPrefix = "in"
    public static let untilPrefix = "Until"
    public static let untilLowerPrefix = "until"
    public static let firstTomorrowPrefix = "First tomorrow"
    public static let tmrwPrefix = "tmrw"
    public static let untilUpper = "UNTIL"
    public static let other = "Other"
    public static let last = "Last"
    public static let lastTodayWasPrefix = "Last today was"
    public static let lastUpper = "LAST"
    public static let phaseIToPhaseII = "Phase I → Phase II"
    public static let phaseIIToPhaseI = "Phase II → Phase I"
    public static let compactHourPlus = "1H+"
    public static let shuttleRectangular = "Shuttle · Rectangular"
    public static let shuttleCircular = "Shuttle · Circular"
    public static let shuttleInline = "Shuttle · Inline"
    public static let shuttleCorner = "Shuttle · Corner"
    public static let lockRectangularDescription = "Lock-screen widget with route, departure time, and countdown."
    public static let lockCircularDescription = "Compact bus icon and departure time."
    public static let lockInlineDescription = "Single-line departure summary next to the time."
    public static let watchCircularDescription = "Bus icon and next departure."
    public static let watchRectangularDescription = "Route, time, and countdown."
    public static let watchInlineDescription = "Single-line summary alongside the time."
    public static let watchCornerDescription = "Corner of the Infograph face."

    public static func minutes(_ value: Int) -> String {
        "\(value)m"
    }

    public static func serviceStartLoop(_ startTime: String) -> String {
        "\(startTime) Loop"
    }

    public static func loopActiveUntil(_ deadline: String) -> String {
        "\(loopActive) until \(deadline)"
    }

    public static func until(_ deadline: String) -> String {
        "\(untilPrefix) \(deadline)"
    }

    public static func firstTomorrow(_ value: String) -> String {
        "\(firstTomorrowPrefix) \(value)"
    }

    public static func returnImmediatelyMultiline(_ lineBreak: String = "\n") -> String {
        "Return\(lineBreak)Immediately"
    }

    public static func lastTodayWas(_ value: String) -> String {
        "\(lastTodayWasPrefix) \(value)"
    }

    public static func other(_ value: String) -> String {
        "\(other) \(value)"
    }
}
