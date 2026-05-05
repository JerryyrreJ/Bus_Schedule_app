//
//  ScheduleQueries.swift
//  Bus_Schedule
//
//  Schedule extensions used by the Widget for: end-of-service detection,
//  Return Immediately deadline lookup, urgency thresholds, and tomorrow's
//  first-bus calculation. Shared with the main app target via Target
//  Membership in Xcode.
//

import Foundation

/// Visual urgency band for a countdown — drives Widget styling
/// (default → warm amber → critical red) and the "Move now" affordance.
enum WidgetUrgency {
    case normal     // > 5 min remaining
    case warm       // 3 < t ≤ 5 min
    case critical   // ≤ 3 min

    static func from(secondsRemaining: Int) -> WidgetUrgency {
        if secondsRemaining <= 3 * 60  { return .critical }
        if secondsRemaining <= 5 * 60  { return .warm }
        return .normal
    }
}

extension Schedule {

    /// First scheduled departure of the day for a given route.
    /// Skips empty cells and "Return Immediately" markers.
    static func firstDeparture(for location: Location, dayType: DayType) -> String? {
        for busTime in getCurrentSchedule(dayType) {
            let t = location == .phIINewCampus ? busTime.phII : busTime.phI
            if !t.isEmpty && t != "Return Immediately" { return t }
        }
        return nil
    }

    /// Last scheduled departure of the day for a given route.
    static func lastDeparture(for location: Location, dayType: DayType) -> String? {
        for busTime in getCurrentSchedule(dayType).reversed() {
            let t = location == .phIINewCampus ? busTime.phII : busTime.phI
            if !t.isEmpty && t != "Return Immediately" { return t }
        }
        return nil
    }

    /// If a Return Immediately window is currently active for Phase I → Phase II,
    /// return the deadline (the next non-RI Phase I departure that ends the loop).
    /// Returns nil if no RI window is active at the given moment.
    static func returnImmediatelyDeadline(
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> String? {
        let schedule = getCurrentSchedule(dayType)
        for index in schedule.indices {
            let busTime = schedule[index]
            guard busTime.phI == "Return Immediately",
                  let startSeconds = secondsFromTimeString(busTime.phII),
                  index + 1 < schedule.count,
                  let endSeconds = secondsFromTimeString(schedule[index + 1].phII) else {
                continue
            }
            guard currentSecondsFromMidnight >= startSeconds,
                  currentSecondsFromMidnight < endSeconds else {
                continue
            }
            // Find the next non-RI Phase I time after the loop window.
            for j in (index + 1)..<schedule.count {
                let t = schedule[j].phI
                if !t.isEmpty && t != "Return Immediately" {
                    return t
                }
            }
            // Fallback: the start of the next bus's Phase II departure.
            return schedule[index + 1].phII
        }
        return nil
    }

    /// Day type for the calendar day after `referenceDate`. Used by the
    /// "Service ended" state to compute first-bus-tomorrow. Note: tomorrow's
    /// day type is auto-detected only — manual override is intentionally a
    /// "today only" affordance and doesn't carry forward.
    static func nextDayType(after referenceDate: Date) -> (dayType: DayType, date: Date) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        return (DayType.automatic(for: tomorrow), tomorrow)
    }

    /// Convenience: seconds-from-midnight for the given calendar date.
    static func secondsFromMidnight(for date: Date) -> Int {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let s = cal.component(.second, from: date)
        return h * 3600 + m * 60 + s
    }

    /// Compute remaining seconds until a scheduled departure, given the
    /// current moment. Returns 0 if the bus has already left.
    static func secondsRemaining(
        until departureSecondsFromMidnight: Int,
        from currentSecondsFromMidnight: Int
    ) -> Int {
        max(0, departureSecondsFromMidnight - currentSecondsFromMidnight)
    }
}

// MARK: - Countdown formatting

enum CountdownFormatter {
    /// Human-friendly countdown: "2m 14s" / "12m" / "1h 23m".
    /// Uses seconds granularity only when ≤ 1 minute — keeps the widget calm
    /// when the bus is far away.
    static func string(forSeconds seconds: Int) -> String {
        if seconds <= 0 { return "Now" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 {
            // Show seconds only when ≤ 5 min — sub-minute precision matters here.
            if seconds <= 5 * 60 {
                let mins = seconds / 60
                let secs = seconds % 60
                return String(format: "%dm %02ds", mins, secs)
            }
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }
}
