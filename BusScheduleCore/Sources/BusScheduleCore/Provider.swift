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

    public init(date: Date, primaryRoute: Location, dayType: DayType, isManualOverride: Bool) {
        self.date = date
        self.primaryRoute = primaryRoute
        self.dayType = dayType
        self.isManualOverride = isManualOverride
    }

    public var currentSecondsFromMidnight: Int {
        Schedule.secondsFromMidnight(for: date)
    }
}

public struct ShuttleProvider: TimelineProvider {
    public typealias Entry = ShuttleEntry

    public init() {}

    public func placeholder(in context: Context) -> ShuttleEntry {
        ShuttleEntry(
            date: Date(),
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

    /// Builds the full timeline: minute-resolution entries for the first
    /// hour, then 5-minute entries for the next three hours, and a 4-hour
    /// refresh policy. Exposed for the intent-based provider.
    public static func makeTimeline(from now: Date) -> Timeline<ShuttleEntry> {
        var entries: [ShuttleEntry] = []

        for i in 0..<60 {
            let t = now.addingTimeInterval(Double(i) * 60)
            entries.append(snapshot(at: t))
        }
        for i in 1...36 {
            let t = now.addingTimeInterval(60 * 60 + Double(i) * 5 * 60)
            entries.append(snapshot(at: t))
        }

        let nextRefresh = now.addingTimeInterval(4 * 60 * 60)
        return Timeline(entries: entries, policy: .after(nextRefresh))
    }
}
