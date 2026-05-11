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

public enum CircularComplicationState: Sendable {
    case scheduled(
        departureTime: String,
        departureDate: Date,
        gaugeStartDate: Date?
    )
    case beforeFirstDeparture(
        departureTime: String,
        departureDate: Date
    )
    case returnImmediately
    case noMoreBuses
}

public enum ServiceStart: Sendable, Equatable {
    case scheduled(time: String)
    case returnImmediately(startTime: String)

    public var startTime: String {
        switch self {
        case let .scheduled(time):
            return time
        case let .returnImmediately(startTime):
            return startTime
        }
    }

    public var displayText: String {
        switch self {
        case let .scheduled(time):
            return time
        case let .returnImmediately(startTime):
            return "\(startTime) Loop"
        }
    }

    public var compactDisplayText: String {
        switch self {
        case let .scheduled(time):
            return time
        case let .returnImmediately(startTime):
            return startTime
        }
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

    static func firstServiceStart(for location: Location, dayType: DayType) -> ServiceStart? {
        for busTime in getCurrentSchedule(dayType) {
            let timeString = location == .phIINewCampus ? busTime.phII : busTime.phI

            if location == .phIParkingLot,
               timeString == "Return Immediately",
               secondsFromTimeString(busTime.phII) != nil {
                return .returnImmediately(startTime: busTime.phII)
            }

            if !timeString.isEmpty,
               timeString != "Return Immediately",
               secondsFromTimeString(timeString) != nil {
                return .scheduled(time: timeString)
            }
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
            return schedule[index + 1].phII
        }
        return nil
    }

    static func nextDayType(after referenceDate: Date) -> (dayType: DayType, date: Date) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        return (DayType.automatic(for: tomorrow), tomorrow)
    }

    static func nextServiceDay(
        after referenceDate: Date,
        currentDayType: DayType,
        isManualOverride: Bool
    ) -> (dayType: DayType, date: Date) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        let dayType = isManualOverride ? currentDayType : DayType.automatic(for: tomorrow)
        return (dayType, tomorrow)
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

    static func nextScheduledDeparture(
        for location: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> (time: String, departureSecondsFromMidnight: Int)? {
        let schedule = getCurrentSchedule(dayType)

        for busTime in schedule {
            let timeString = location == .phIINewCampus ? busTime.phII : busTime.phI

            guard let departureSeconds = secondsFromTimeString(timeString),
                  departureSeconds > currentSecondsFromMidnight else {
                continue
            }

            return (timeString, departureSeconds)
        }

        return nil
    }

    static func circularComplicationState(
        for location: Location,
        dayType: DayType,
        at date: Date
    ) -> CircularComplicationState {
        let currentSecondsFromMidnight = secondsFromMidnight(for: date)

        if location == .phIParkingLot {
            let state = nextDepartureState(
                for: location,
                dayType: dayType,
                currentSecondsFromMidnight: currentSecondsFromMidnight
            )
            if case .returnImmediately = state {
                return .returnImmediately
            }
        }

        guard let next = nextScheduledDeparture(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSecondsFromMidnight
        ) else {
            return .noMoreBuses
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let departureDate = startOfDay.addingTimeInterval(TimeInterval(next.departureSecondsFromMidnight))

        if let previousSeconds = previousDepartureSeconds(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSecondsFromMidnight
        ) {
            let gaugeStartDate = startOfDay.addingTimeInterval(TimeInterval(previousSeconds))
            return .scheduled(
                departureTime: next.time,
                departureDate: departureDate,
                gaugeStartDate: gaugeStartDate
            )
        }

        return .beforeFirstDeparture(
            departureTime: next.time,
            departureDate: departureDate
        )
    }

    static func nextInterestingRefreshDate(
        for location: Location,
        dayType: DayType,
        isManualOverride: Bool = false,
        after date: Date
    ) -> Date? {
        let currentSecondsFromMidnight = secondsFromMidnight(for: date)
        let startOfDay = Calendar.current.startOfDay(for: date)

        switch circularComplicationState(for: location, dayType: dayType, at: date) {
        case let .scheduled(_, departureDate, _):
            if let nextBoundary = nextHourlyCountdownRefreshDate(
                departureDate: departureDate,
                referenceDate: date
            ) {
                return nextBoundary
            }
            return departureDate.addingTimeInterval(1)

        case let .beforeFirstDeparture(_, departureDate):
            if let nextBoundary = nextHourlyCountdownRefreshDate(
                departureDate: departureDate,
                referenceDate: date
            ) {
                return nextBoundary
            }
            return departureDate.addingTimeInterval(1)

        case .returnImmediately:
            if let deadline = returnImmediatelyDeadline(
                dayType: dayType,
                currentSecondsFromMidnight: currentSecondsFromMidnight
            ),
               let endSeconds = secondsFromTimeString(deadline) {
                return startOfDay.addingTimeInterval(TimeInterval(endSeconds) + 1)
            }
            return nil

        case .noMoreBuses:
            let next = nextServiceDay(
                after: date,
                currentDayType: dayType,
                isManualOverride: isManualOverride
            )
            guard let first = firstServiceStart(for: location, dayType: next.dayType),
                  let firstSeconds = secondsFromTimeString(first.startTime) else {
                return nil
            }
            return Calendar.current.startOfDay(for: next.date)
                .addingTimeInterval(TimeInterval(firstSeconds))
        }
    }

    private static func nextHourlyCountdownRefreshDate(
        departureDate: Date,
        referenceDate: Date
    ) -> Date? {
        let remaining = max(0, Int(departureDate.timeIntervalSince(referenceDate)))
        guard remaining > 3600 else { return nil }

        let displayedHours = Int(ceil(Double(remaining) / 3600.0))
        let nextBoundary = departureDate
            .addingTimeInterval(-TimeInterval((displayedHours - 1) * 3600))
            .addingTimeInterval(1)

        return nextBoundary > referenceDate ? nextBoundary : nil
    }

    /// Seconds-from-midnight of the most recent departure that has already left
    /// today, for the given location. Returns `nil` if no bus has left yet
    /// (i.e., we're before the day's first departure). "Return Immediately"
    /// rows are skipped.
    ///
    /// Used to render the wait-progress bar: progress goes from 0 right after
    /// the previous bus leaves to 1 as the next bus arrives.
    static func previousDepartureSeconds(
        for location: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> Int? {
        var lastSeen: Int? = nil
        for busTime in getCurrentSchedule(dayType) {
            let timeString = location == .phIINewCampus ? busTime.phII : busTime.phI
            guard timeString != "Return Immediately",
                  let s = secondsFromTimeString(timeString),
                  s <= currentSecondsFromMidnight else {
                continue
            }
            lastSeen = s
        }
        return lastSeen
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
