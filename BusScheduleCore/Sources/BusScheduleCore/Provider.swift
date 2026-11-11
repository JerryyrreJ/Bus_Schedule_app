//
//  Provider.swift
//  BusScheduleCore
//
//  Shared TimelineProvider for iPhone Widget Extension and watchOS
//  complications. Both targets register their own Widget definitions but
//  pull from the same Provider so the timeline shape stays consistent.
//

import WidgetKit
import Foundation

public struct ShuttleEntry: TimelineEntry {
    public let date: Date
    public let primaryRoute: Location
    public let dayType: DayType
    public let isManualOverride: Bool
    #if DEBUG
    /// Layout fixtures only; never present in a Release build or persisted.
    public var previewCountdownSeconds: Int?
    #endif

    public init(date: Date, primaryRoute: Location, dayType: DayType, isManualOverride: Bool) {
        self.date = date
        self.primaryRoute = primaryRoute
        self.dayType = dayType
        self.isManualOverride = isManualOverride
    }

    public var currentSecondsFromMidnight: Int {
        Schedule.secondsFromMidnight(for: date)
    }

    public func nextDepartureState(for route: Location) -> NextDepartureState {
        #if DEBUG
        if let seconds = previewCountdownSeconds {
            return .scheduled(time: previewTime(after: seconds), departureSecondsFromMidnight: currentSecondsFromMidnight + seconds)
        }
        #endif
        return Schedule.nextDepartureState(for: route, dayType: dayType, currentSecondsFromMidnight: currentSecondsFromMidnight)
    }

    public func upcomingDepartures(for route: Location, limit: Int) -> [String] {
        #if DEBUG
        if let seconds = previewCountdownSeconds {
            return (0..<max(0, limit)).map { previewTime(after: seconds + ($0 + 1) * 1800) }
        }
        #endif
        return Schedule.upcomingDepartures(for: route, dayType: dayType, currentSecondsFromMidnight: currentSecondsFromMidnight, limit: limit)
    }

    #if DEBUG
    private func previewTime(after seconds: Int) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date.addingTimeInterval(TimeInterval(seconds)))
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
    #endif
}

public struct ShuttleProvider: TimelineProvider {
    public typealias Entry = ShuttleEntry

    public init() {}

    public func placeholder(in context: Context) -> ShuttleEntry {
        Self.placeholderEntry()
    }

    public static func placeholderEntry() -> ShuttleEntry {
        let representativeDate = Calendar.current.date(
            bySettingHour: 8,
            minute: 2,
            second: 0,
            of: Date()
        ) ?? Date()
        return ShuttleEntry(
            date: representativeDate,
            primaryRoute: .phIINewCampus,
            dayType: .weekday,
            isManualOverride: false
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (ShuttleEntry) -> Void) {
        completion(Self.snapshot(at: Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<ShuttleEntry>) -> Void) {
        completion(Self.makeTimeline(from: Date()))
    }

    /// Builds a single entry for the given moment. Exposed so the
    /// intent-based provider in the widget target can reuse the same logic.
    public static func snapshot(at date: Date) -> ShuttleEntry {
        let resolved = DayType.effective(for: date)
        return ShuttleEntry(
            date: date,
            primaryRoute: SharedStore.readPrimaryRoute(),
            dayType: resolved.dayType,
            isManualOverride: resolved.isManualOverride
        )
    }

    /// Builds a 4-hour timeline aligned to exact `:00` whole-minute boundaries so
    /// scheduled departures (HH:mm:00) and midnight rollovers transition on the
    /// exact second instead of lagging by arbitrary sub-minute or 5-minute offsets.
    public static func makeTimeline(from now: Date) -> Timeline<ShuttleEntry> {
        let route = SharedStore.readPrimaryRoute()
        return makeTimeline(from: now, primaryRoute: route) { date in
            DayType.effective(for: date)
        }
    }

    static func makeTimeline(
        from now: Date,
        primaryRoute: Location,
        resolveDayType: (Date) -> (dayType: DayType, isManualOverride: Bool)
    ) -> Timeline<ShuttleEntry> {
        let endDate = now.addingTimeInterval(4 * 60 * 60)
        var entries: [ShuttleEntry] = []
        entries.reserveCapacity(241)

        func makeEntry(at date: Date) -> ShuttleEntry {
            let resolved = resolveDayType(date)
            return ShuttleEntry(
                date: date,
                primaryRoute: primaryRoute,
                dayType: resolved.dayType,
                isManualOverride: resolved.isManualOverride
            )
        }

        entries.append(makeEntry(at: now))

        let firstMinuteTimestamp = floor(now.timeIntervalSince1970 / 60.0) * 60.0 + 60.0
        var cursor = Date(timeIntervalSince1970: firstMinuteTimestamp)

        while cursor < endDate {
            entries.append(makeEntry(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }

        return Timeline(entries: entries, policy: .after(endDate))
    }

    /// Bound the number of entries, then ask WidgetKit to reload when they end.
    /// Inject the resolver so tests do not need an entitled App Group container.
    public static func makeComplicationTimeline(
        from now: Date,
        primaryRoute: Location,
        calendar: Calendar = .current,
        resolveDayType: (Date) -> (dayType: DayType, isManualOverride: Bool)
    ) -> Timeline<ShuttleEntry> {
        func entry(at date: Date) -> ShuttleEntry {
            let resolved = resolveDayType(date)
            return ShuttleEntry(date: date, primaryRoute: primaryRoute,
                                dayType: resolved.dayType, isManualOverride: resolved.isManualOverride)
        }

        let horizon = now.addingTimeInterval(6 * 60 * 60)
        var entries = [entry(at: now)]
        var cursor = now
        while entries.count < 60, cursor < horizon {
            let resolved = resolveDayType(cursor)
            guard let boundary = Schedule.nextInterestingRefreshDate(
                for: primaryRoute, dayType: resolved.dayType,
                isManualOverride: resolved.isManualOverride, after: cursor, calendar: calendar
            ), boundary > cursor else { break }
            let next = min(boundary, horizon)
            entries.append(entry(at: next))
            cursor = next
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

}

