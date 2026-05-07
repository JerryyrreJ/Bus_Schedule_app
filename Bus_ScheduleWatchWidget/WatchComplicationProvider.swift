//
//  WatchComplicationProvider.swift
//  Bus_ScheduleWatchWidget
//
//  A watch-specific provider that emits sparse timeline entries and relies on
//  dynamic date/progress views for the circular complication's live countdown.
//

import Foundation
import WidgetKit
import BusScheduleCore

struct WatchComplicationProvider: TimelineProvider {
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
        var entries: [ShuttleEntry] = [snapshot(at: now)]
        var cursor = now

        for _ in 0..<8 {
            let resolved = DayType.effective(for: cursor)
            guard let next = Schedule.nextInterestingRefreshDate(
                for: SharedStore.readPrimaryRoute(),
                dayType: resolved.dayType,
                isManualOverride: resolved.isManualOverride,
                after: cursor
            ) else {
                break
            }

            if next <= cursor {
                break
            }

            entries.append(snapshot(at: next))
            cursor = next
        }

        let fallbackRefresh = now.addingTimeInterval(6 * 60 * 60)
        completion(Timeline(entries: entries, policy: .after(fallbackRefresh)))
    }

    private func snapshot(at date: Date) -> ShuttleEntry {
        let resolved = DayType.effective(for: date)
        return ShuttleEntry(
            date: date,
            primaryRoute: SharedStore.readPrimaryRoute(),
            dayType: resolved.dayType,
            isManualOverride: resolved.isManualOverride
        )
    }
}
