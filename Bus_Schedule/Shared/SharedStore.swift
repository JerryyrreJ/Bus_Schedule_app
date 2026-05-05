//
//  SharedStore.swift
//  Bus_Schedule
//
//  Constants, persistence, and helpers shared between the main app target
//  and the Bus_ScheduleWidget extension. Both targets must include this file
//  in their compile sources (set via Target Membership in Xcode).
//

import Foundation

enum SharedStore {
    /// App Group identifier — must match the entitlement on both targets.
    /// Mirrored in: Bus_Schedule.entitlements + Bus_ScheduleWidget.entitlements.
    static let appGroup = "group.Jerry-Lu.Bus-Schedule"

    /// Shared UserDefaults suite. Falls back to `.standard` if the App Group
    /// entitlement isn't yet configured (e.g. running before Xcode setup).
    /// Once both targets carry the App Group, both processes read/write the
    /// same backing store.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Storage key for the persisted manual override. "" = follow auto.
    static let dayTypeOverrideKey = "dayTypeOverride"

    /// Returns the persisted manual override, or nil if "follow auto".
    static func readOverride() -> DayType? {
        let raw = defaults.string(forKey: dayTypeOverrideKey) ?? ""
        return raw.isEmpty ? nil : DayType(rawValue: raw)
    }

    /// Persist a manual override. Pass nil to clear (back to "follow auto").
    static func writeOverride(_ dayType: DayType?) {
        if let dayType {
            defaults.set(dayType.rawValue, forKey: dayTypeOverrideKey)
        } else {
            defaults.set("", forKey: dayTypeOverrideKey)
        }
    }

    /// Self-heal the override: if it now matches what auto would return, drop
    /// it. Call from the main app on launch / foreground / midnight rollover.
    /// Don't call from the widget extension — TimelineProvider snapshot work
    /// should be side-effect free.
    static func selfHealOverride(for date: Date = Date()) {
        guard let override = readOverride() else { return }
        if override == DayType.automatic(for: date) {
            writeOverride(nil)
        }
    }
}

// MARK: - DayType helpers shared across targets

extension DayType {
    /// Auto-detect the day type for a given calendar date. Holiday detection
    /// is intentionally absent — the manual override exists to compensate.
    static func automatic(for date: Date) -> DayType {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 7:  return .saturday
        case 1:  return .sundayOrHoliday
        default: return .weekday
        }
    }

    /// Resolve the effective day type after applying any manual override.
    /// No side effects — safe to call from a TimelineProvider.
    static func effective(for date: Date = Date()) -> (dayType: DayType, isManualOverride: Bool) {
        let auto = DayType.automatic(for: date)
        guard let override = SharedStore.readOverride() else {
            return (auto, false)
        }
        if override == auto {
            // Override is redundant; surface it as auto without rewriting storage.
            return (auto, false)
        }
        return (override, true)
    }

    /// Cycle order for the override chip's tap action:
    /// Auto → first non-auto manual → second non-auto manual → Auto.
    /// Skips the auto-matching value so a tap never produces a no-op.
    static func nextOverrideInCycle(from current: DayType?, currentAuto: DayType) -> DayType? {
        let manualOptions = DayType.allCases.filter { $0 != currentAuto }
        guard manualOptions.count == 2 else { return nil }

        switch current {
        case nil:
            return manualOptions[0]
        case manualOptions[0]:
            return manualOptions[1]
        case manualOptions[1]:
            return nil
        default:
            return nil
        }
    }
}
