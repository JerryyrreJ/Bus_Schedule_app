//
//  ToggleDayTypeIntent.swift
//  BusScheduleCore
//
//  AppIntent powering the override chip's tap action. Lives in the package so
//  iPhone Widget, iPhone main app, watchOS app, and watchOS complications can
//  all reference the same intent type.
//

import AppIntents
import WidgetKit

public struct ToggleDayTypeIntent: AppIntent {
    public static var title: LocalizedStringResource { "Cycle Schedule Override" }
    public static var description: IntentDescription? {
        IntentDescription(
        "Cycles the schedule override between Auto, Weekday, Saturday, and Holiday."
        )
    }

    public static var isDiscoverable: Bool { false }

    public init() {}

    public func perform() async throws -> some IntentResult {
        let now = Date()
        let auto = DayType.automatic(for: now)
        let current = SharedStore.readOverride()
        let next = DayType.nextOverrideInCycle(from: current, currentAuto: auto)

        SharedStore.writeOverride(next)
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
