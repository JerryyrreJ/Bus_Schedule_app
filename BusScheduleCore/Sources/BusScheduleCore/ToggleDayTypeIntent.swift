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
    public static let title: LocalizedStringResource = "Cycle Schedule Override"

    public static let description = IntentDescription(
        "Cycle the schedule override between Auto, Weekday, Saturday, and Holiday."
    )

    public static let isDiscoverable: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        let now = Date()
        let auto = DayType.automatic(for: now)
        let current = SharedStore.readOverride(for: now)
        let next = DayType.nextOverrideInCycle(from: current, currentAuto: auto)

        SharedStore.writeOverride(next, sourceDate: now)
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
