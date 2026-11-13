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
            return BusScheduleStrings.serviceStartLoop(startTime)
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

public enum TimetableRowStatus: Sendable, Equatable {
    case past
    case activeLoop
    case nextPrimary
    case upcoming
}

public struct TimetableRow: Identifiable, Sendable, Equatable {
    public let id: Int
    public let phIITime: String?
    public let phITime: String?
    public let isPhIReturnImmediately: Bool
    public let isPhIIPast: Bool
    public let isPhIPast: Bool
    public let status: TimetableRowStatus

    public var isHighlighted: Bool {
        status == .activeLoop || status == .nextPrimary
    }
}

public extension Schedule {

    static func firstDeparture(for location: Location, dayType: DayType) -> String? {
        for busTime in getCurrentSchedule(dayType) {
            let t = location == .phIINewCampus ? busTime.phII : busTime.phI
            if !t.isEmpty && t != BusScheduleStrings.returnImmediatelyToken { return t }
        }
        return nil
    }

    static func firstServiceStart(for location: Location, dayType: DayType) -> ServiceStart? {
        for busTime in getCurrentSchedule(dayType) {
            let timeString = location == .phIINewCampus ? busTime.phII : busTime.phI

            if location == .phIParkingLot,
               timeString == BusScheduleStrings.returnImmediatelyToken,
               secondsFromTimeString(busTime.phII) != nil {
                return .returnImmediately(startTime: busTime.phII)
            }

            if !timeString.isEmpty,
               timeString != BusScheduleStrings.returnImmediatelyToken,
               secondsFromTimeString(timeString) != nil {
                return .scheduled(time: timeString)
            }
        }

        return nil
    }

    static func lastDeparture(for location: Location, dayType: DayType) -> String? {
        for busTime in getCurrentSchedule(dayType).reversed() {
            let t = location == .phIINewCampus ? busTime.phII : busTime.phI
            if !t.isEmpty && t != BusScheduleStrings.returnImmediatelyToken { return t }
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
            guard busTime.phI == BusScheduleStrings.returnImmediatelyToken,
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
        currentDayType _: DayType,
        isManualOverride _: Bool,
        calendar: Calendar = .current
    ) -> (dayType: DayType, date: Date) {
        // Overrides expire at midnight, so tomorrow always uses its automatic type.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        return (DayType.automatic(for: tomorrow, calendar: calendar), tomorrow)
    }

    static func secondsFromMidnight(for date: Date, calendar: Calendar = .current) -> Int {
        let cal = calendar
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
        at date: Date,
        calendar: Calendar = .current
    ) -> CircularComplicationState {
        let currentSecondsFromMidnight = secondsFromMidnight(for: date, calendar: calendar)

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

        let startOfDay = calendar.startOfDay(for: date)
        let departureDate = calendar.date(bySettingHour: next.departureSecondsFromMidnight / 3600,
                                          minute: next.departureSecondsFromMidnight % 3600 / 60,
                                          second: 0, of: date) ?? date

        if let previousSeconds = previousDepartureSeconds(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSecondsFromMidnight
        ) {
            let gaugeStartDate = calendar.date(bySettingHour: previousSeconds / 3600,
                                               minute: previousSeconds % 3600 / 60,
                                               second: 0, of: date) ?? startOfDay
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
        isManualOverride _: Bool = false,
        after date: Date,
        calendar: Calendar = .current
    ) -> Date? {
        let currentSeconds = secondsFromMidnight(for: date, calendar: calendar)
        // Midnight changes the effective day type, override validity and "tomorrow".
        var candidates = [SharedStore.nextStartOfDay(after: date, calendar: calendar)]

        switch circularComplicationState(for: location, dayType: dayType, at: date, calendar: calendar) {
        case let .scheduled(_, departureDate, _), let .beforeFirstDeparture(_, departureDate):
            if let nextBoundary = nextCircularCountdownRefreshDate(
                departureDate: departureDate, referenceDate: date
            ) {
                candidates.append(nextBoundary)
            }
        case .returnImmediately:
            if let deadline = returnImmediatelyDeadline(
                dayType: dayType, currentSecondsFromMidnight: currentSeconds
            ), let end = secondsFromTimeString(deadline),
               let endDate = calendar.date(bySettingHour: end / 3600,
                                           minute: end % 3600 / 60,
                                           second: 0, of: date) {
                candidates.append(endDate)
            }
        case .noMoreBuses:
            break // Re-resolve at midnight before planning the next day's service.
        }

        // A pickup loop may start before the next fixed-time departure.
        if location == .phIParkingLot {
            let schedule = getCurrentSchedule(dayType)
            for index in schedule.indices {
                guard schedule[index].phI == BusScheduleStrings.returnImmediatelyToken,
                      index == schedule.startIndex || schedule[index - 1].phI != BusScheduleStrings.returnImmediatelyToken,
                      let start = secondsFromTimeString(schedule[index].phII),
                      start > currentSeconds,
                      let startDate = calendar.date(bySettingHour: start / 3600,
                                                    minute: start % 3600 / 60,
                                                    second: 0, of: date) else { continue }
                candidates.append(startDate)
            }
        }

        return candidates.filter { $0 > date }.min()
    }

    static func waitProgressFraction(
        for location: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> Double {
        guard case let .scheduled(_, departureSecondsFromMidnight) = nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSecondsFromMidnight
        ) else {
            return 0
        }

        guard let previousSeconds = previousDepartureSeconds(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSecondsFromMidnight
        ) else {
            return 0
        }

        let total = Double(max(1, departureSecondsFromMidnight - previousSeconds))
        let elapsed = Double(max(0, currentSecondsFromMidnight - previousSeconds))
        return min(1.0, elapsed / total)
    }

    private static func nextCircularCountdownRefreshDate(
        departureDate: Date,
        referenceDate: Date
    ) -> Date? {
        let remaining = departureDate.timeIntervalSince(referenceDate)
        guard remaining > 0 else { return nil }

        if remaining > 60 {
            let nextBoundary = departureDate
                .addingTimeInterval(-TimeInterval((Int(ceil(remaining / 60.0)) - 1) * 60))
            return nextBoundary > referenceDate ? nextBoundary : nil
        }

        let nextBoundary = departureDate
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
            guard timeString != BusScheduleStrings.returnImmediatelyToken,
                  let s = secondsFromTimeString(timeString),
                  s <= currentSecondsFromMidnight else {
                continue
            }
            lastSeen = s
        }
        return lastSeen
    }

    /// Builds paired Phase II ↔ Phase I timetable rows for the companion schedule board,
    /// marking past runs, upcoming runs, and the single active loop / next primary departure.
    static func timetableRows(
        for primaryLocation: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> [TimetableRow] {
        let schedule = getCurrentSchedule(dayType)

        struct RawRow {
            let id: Int
            let phIITime: String?
            let phITime: String?
            let isPhIReturnImmediately: Bool
            let isPhIIPast: Bool
            let isPhIPast: Bool
            let isLoopActiveNow: Bool
        }

        var rawRows: [RawRow] = []
        rawRows.reserveCapacity(schedule.count)

        for index in schedule.indices {
            let busTime = schedule[index]
            let isLoop = busTime.phI == BusScheduleStrings.returnImmediatelyToken

            let phIISeconds = secondsFromTimeString(busTime.phII)
            let phIITime = phIISeconds != nil ? busTime.phII : nil
            let isPhIIPast = phIISeconds.map { $0 <= currentSecondsFromMidnight } ?? true

            let phISeconds = isLoop ? nil : secondsFromTimeString(busTime.phI)
            let phITime = phISeconds != nil ? busTime.phI : nil

            let loopEndSeconds: Int? = {
                guard isLoop, index + 1 < schedule.count else { return nil }
                return secondsFromTimeString(schedule[index + 1].phII)
            }()

            let isLoopActiveNow: Bool = {
                guard isLoop,
                      let start = phIISeconds,
                      let end = loopEndSeconds else { return false }
                return currentSecondsFromMidnight >= start && currentSecondsFromMidnight < end
            }()

            let isPhIPast: Bool = {
                if isLoop {
                    guard let end = loopEndSeconds else { return true }
                    return currentSecondsFromMidnight >= end
                }
                guard let phISeconds else { return true }
                return phISeconds <= currentSecondsFromMidnight
            }()

            rawRows.append(RawRow(
                id: busTime.id,
                phIITime: phIITime,
                phITime: phITime,
                isPhIReturnImmediately: isLoop,
                isPhIIPast: isPhIIPast,
                isPhIPast: isPhIPast,
                isLoopActiveNow: isLoopActiveNow
            ))
        }

        let activeLoopRowID: Int? = primaryLocation == .phIParkingLot
            ? rawRows.first(where: \.isLoopActiveNow)?.id
            : nil

        let nextPrimaryRowID: Int? = {
            guard activeLoopRowID == nil else { return nil }
            switch primaryLocation {
            case .phIINewCampus:
                return rawRows.first(where: { $0.phIITime != nil && !$0.isPhIIPast })?.id
            case .phIParkingLot:
                return rawRows.first(where: { $0.phITime != nil && !$0.isPhIPast })?.id
            }
        }()

        return rawRows.map { raw in
            let status: TimetableRowStatus
            if raw.id == activeLoopRowID {
                status = .activeLoop
            } else if raw.id == nextPrimaryRowID {
                status = .nextPrimary
            } else if raw.isPhIIPast && raw.isPhIPast {
                status = .past
            } else {
                status = .upcoming
            }

            return TimetableRow(
                id: raw.id,
                phIITime: raw.phIITime,
                phITime: raw.phITime,
                isPhIReturnImmediately: raw.isPhIReturnImmediately,
                isPhIIPast: raw.isPhIIPast,
                isPhIPast: raw.isPhIPast,
                status: status
            )
        }
    }

    static func remainingRunCount(
        for location: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> Int {
        let rows = timetableRows(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSecondsFromMidnight
        )
        return rows.reduce(into: 0) { count, row in
            switch location {
            case .phIINewCampus:
                if row.phIITime != nil && !row.isPhIIPast { count += 1 }
            case .phIParkingLot:
                if (row.phITime != nil || row.isPhIReturnImmediately) && !row.isPhIPast { count += 1 }
            }
        }
    }
}

public enum CountdownFormatter {
    /// Widgets refresh on minute timelines. Round up instead of displaying stale
    /// seconds or claiming a bus is due before its departure. At most six glyphs
    /// for a day's wait: 59m, 1h45m, 10h02m. `h` distinguishes a duration from 10:02.
    public static func widgetString(forSeconds seconds: Int) -> String {
        if seconds <= 0 { return BusScheduleStrings.now }
        if seconds < 60 { return "<1m" }
        let totalMinutes = widgetMinutes(forSeconds: seconds)
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0 ? "\(hours)h" : String(format: "%dh%02dm", hours, minutes)
    }

    public static func widgetMinutes(forSeconds seconds: Int) -> Int {
        guard seconds > 0 else { return 0 }
        return seconds / 60 + (seconds % 60 == 0 ? 0 : 1)
    }

    public static func string(forSeconds seconds: Int) -> String {
        if seconds <= 0 { return BusScheduleStrings.now }
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

