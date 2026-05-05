//
//  ToggleDayTypeIntent.swift
//  Bus_Schedule
//
//  AppIntent powering the Widget's override-chip tap action. Cycles
//  Auto → Manual1 → Manual2 → Auto, skipping the value that matches
//  today's auto-detected day type so a tap never produces a no-op.
//
//  Must be a member of BOTH targets:
//    - Main app (so the system can register the intent)
//    - Widget extension (so the widget can construct the intent)
//

import AppIntents
import WidgetKit

struct ToggleDayTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Cycle Schedule Override"
    static var description = IntentDescription(
        "Cycles the schedule override between Auto, Weekday, Saturday, and Holiday."
    )

    /// Hidden from Shortcuts — this is widget-internal plumbing, not user-facing.
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        let now = Date()
        let auto = DayType.automatic(for: now)
        let current = SharedStore.readOverride()
        let next = DayType.nextOverrideInCycle(from: current, currentAuto: auto)

        SharedStore.writeOverride(next)
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
