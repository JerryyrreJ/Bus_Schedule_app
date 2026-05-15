//
//  IntentShuttleProvider.swift
//  Bus_ScheduleWidget
//
//  AppIntentTimelineProvider that wraps the shared ShuttleProvider snapshot
//  logic and tags each entry with the user-selected WidgetStyle so the
//  view layer can branch its rendering.
//

import WidgetKit
import BusScheduleCore

struct StyledShuttleEntry: TimelineEntry {
    let base: ShuttleEntry
    let style: WidgetStyle

    var date: Date { base.date }
}

struct IntentShuttleProvider: AppIntentTimelineProvider {
    typealias Entry = StyledShuttleEntry
    typealias Intent = ShuttleHomeIntent

    func placeholder(in context: Context) -> StyledShuttleEntry {
        StyledShuttleEntry(
            base: ShuttleProvider.snapshot(at: Date()),
            style: .card
        )
    }

    func snapshot(for configuration: ShuttleHomeIntent, in context: Context) async -> StyledShuttleEntry {
        StyledShuttleEntry(
            base: ShuttleProvider.snapshot(at: Date()),
            style: configuration.style
        )
    }

    func timeline(for configuration: ShuttleHomeIntent, in context: Context) async -> Timeline<StyledShuttleEntry> {
        let base = ShuttleProvider.makeTimeline(from: Date())
        let styled = base.entries.map {
            StyledShuttleEntry(base: $0, style: configuration.style)
        }
        return Timeline(entries: styled, policy: base.policy)
    }
}
