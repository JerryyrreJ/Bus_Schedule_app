//
//  Provider.swift
//  Bus_ScheduleWidget
//
//  TimelineProvider + TimelineEntry for all Bus Schedule widgets.
//  All widget views read from the same ShuttleEntry — what differs is which
//  parts of it they render at which size.
//

import WidgetKit
import SwiftUI

/// Single source of truth for what a widget needs to render at a given moment.
struct ShuttleEntry: TimelineEntry {
    let date: Date
    let primaryRoute: Location
    let dayType: DayType
    let isManualOverride: Bool

    /// Convenience: seconds-from-midnight at `date`. All Schedule queries
    /// take this as input, so cache it here.
    var currentSecondsFromMidnight: Int {
        Schedule.secondsFromMidnight(for: date)
    }
}

struct ShuttleProvider: TimelineProvider {
    typealias Entry = ShuttleEntry

    func placeholder(in context: Context) -> ShuttleEntry {
        ShuttleEntry(
            date: Date(),
            primaryRoute: .phIINewCampus,
            dayType: .weekday,
            isManualOverride: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShuttleEntry) -> Void) {
        completion(snapshot(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShuttleEntry>) -> Void) {
        let now = Date()
        var entries: [ShuttleEntry] = []

        // Per-minute entries for the next 60 minutes — covers the active
        // glance window where countdown granularity matters.
        for i in 0..<60 {
            let t = now.addingTimeInterval(Double(i) * 60)
            entries.append(snapshot(at: t))
        }
        // Sparser 5-min entries for the next 3 hours — covers casual glances
        // while still letting the system know we don't need per-minute updates.
        for i in 1...36 {
            let t = now.addingTimeInterval(60 * 60 + Double(i) * 5 * 60)
            entries.append(snapshot(at: t))
        }

        // Re-fetch in 4 hours regardless — gives WidgetKit a hard cap so we
        // don't drift if the override changes off-cycle.
        let nextRefresh = now.addingTimeInterval(4 * 60 * 60)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    /// Compose a snapshot for the given moment. Side-effect free —
    /// uses `DayType.effective` (read-only), not the self-healing variant.
    private func snapshot(at date: Date) -> ShuttleEntry {
        let resolved = DayType.effective(for: date)
        return ShuttleEntry(
            date: date,
            primaryRoute: .phIINewCampus,
            dayType: resolved.dayType,
            isManualOverride: resolved.isManualOverride
        )
    }
}
