//
//  ScheduleQueries.swift
//  BusScheduleCore
//
//  Schedule extensions used by widgets / watch app: end-of-service detection,
//  Return Immediately deadline lookup, urgency thresholds, tomorrow's first-bus.
//

import Foundation

public enum WidgetUrgency: Sendable {
    case normal     // > 5 min remaining
    case warm       // 3 < t ≤ 5 min
    case critical   // ≤ 3 min

    public static func from(secondsRemaining: Int) -> WidgetUrgency {
        if secondsRemaining <= 3 * 60  { return .critical }
        if secondsRemaining <= 5 * 60  { return .warm }
        return .normal
    }
}

public extension Schedule {

    static func firstDeparture(for location: Location, dayType: DayType) -> String? {
        for busTime in getCurrentSchedule(dayType) {
            let t = location == .phIINewCampus ? busTime.phII : busTime.phI
            if !t.isEmpty && t != "Return Immediately" { return t }
        }
        return nil
    }

    static func lastDeparture(for location: Location, dayType: DayType) -> String? {
        for busTime in getCurrentSchedule(dayType).reversed() {
            let t = location == .phIINewCampus ? busTime.phII : busTime.phI
            if !t.isEmpty && t != "Return Immediately" { return t }
        }
        return nil
    }

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
            for j in (index + 1)..<schedule.count {
                let t = schedule[j].phI
                if !t.isEmpty && t != "Return Immediately" {
                    return t
                }
            }
            return schedule[index + 1].phII
        }
        return nil
    }

    static func nextDayType(after referenceDate: Date) -> (dayType: DayType, date: Date) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        return (DayType.automatic(for: tomorrow), tomorrow)
    }

    static func secondsFromMidnight(for date: Date) -> Int {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let s = cal.component(.second, from: date)
        return h * 3600 + m * 60 + s
    }

    static func secondsRemaining(
        until departureSecondsFromMidnight: Int,
        from currentSecondsFromMidnight: Int
    ) -> Int {
        max(0, departureSecondsFromMidnight - currentSecondsFromMidnight)
    }
}

public enum CountdownFormatter {
    public static func string(forSeconds seconds: Int) -> String {
        if seconds <= 0 { return "Now" }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 {
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
