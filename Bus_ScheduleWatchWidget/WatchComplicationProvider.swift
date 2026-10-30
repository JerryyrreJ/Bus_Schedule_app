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
        completion(ShuttleProvider.makeComplicationTimeline(
            from: Date(),
            primaryRoute: SharedStore.readPrimaryRoute(),
            resolveDayType: { DayType.effective(for: $0) }
        ))
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

