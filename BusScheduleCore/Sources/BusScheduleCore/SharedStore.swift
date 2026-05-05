//
//  SharedStore.swift
//  BusScheduleCore
//
//  App Group + iCloud KV-backed persistence for the manual day-type override.
//  Local writes always go to both the App Group UserDefaults and iCloud KV;
//  reads prefer iCloud (most authoritative) and fall back to local.
//
//  Apps must call `SharedStore.startCloudSync()` once at launch to subscribe
//  to remote iCloud changes — that's what propagates the user's iPhone choice
//  to the watch and vice versa.
//

import Foundation
import WidgetKit

public enum SharedStore {
    public static let appGroup = "group.Jerry-Lu.Bus-Schedule"
    public static let dayTypeOverrideKey = "dayTypeOverride"

    public static var localDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private static var cloud: NSUbiquitousKeyValueStore {
        .default
    }

    /// Returns the persisted manual override (nil = follow auto). Prefers
    /// iCloud over local — iCloud wins because it's the source of truth shared
    /// across iPhone and Watch.
    public static func readOverride() -> DayType? {
        let cloudValue = cloud.string(forKey: dayTypeOverrideKey) ?? ""
        if !cloudValue.isEmpty, let parsed = DayType(rawValue: cloudValue) {
            return parsed
        }
        let localValue = localDefaults.string(forKey: dayTypeOverrideKey) ?? ""
        return localValue.isEmpty ? nil : DayType(rawValue: localValue)
    }

    /// Persist a manual override. Pass nil to clear. Writes to both local
    /// (App Group) and iCloud KV so all devices/extensions converge.
    public static func writeOverride(_ dayType: DayType?) {
        let value = dayType?.rawValue ?? ""
        localDefaults.set(value, forKey: dayTypeOverrideKey)
        cloud.set(value, forKey: dayTypeOverrideKey)
        cloud.synchronize()
    }

    /// Self-heal the override: if it now matches what auto would return, drop
    /// it. Call from main apps on launch / foreground / midnight rollover.
    /// Don't call from a TimelineProvider — that's snapshot work, side-effect free.
    public static func selfHealOverride(for date: Date = Date()) {
        guard let override = readOverride() else { return }
        if override == DayType.automatic(for: date) {
            writeOverride(nil)
        }
    }

    /// Subscribe to remote iCloud KV changes. On a remote change: refresh all
    /// widgets/complications and post `.dayTypeOverrideDidChange` for in-app
    /// observers. Idempotent — safe to call from each foreground app's init.
    public static func startCloudSync() {
        guard !didStartCloudSync else { return }
        didStartCloudSync = true

        cloud.synchronize()

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { _ in
            WidgetCenter.shared.reloadAllTimelines()
            NotificationCenter.default.post(name: .dayTypeOverrideDidChange, object: nil)
        }
    }

    nonisolated(unsafe) private static var didStartCloudSync = false
}

public extension Notification.Name {
    static let dayTypeOverrideDidChange = Notification.Name("BusSchedule.dayTypeOverrideDidChange")
}

// MARK: - DayType helpers

public extension DayType {
    /// Auto-detect day type from calendar weekday. Holiday detection is
    /// intentionally absent — the manual override exists to compensate.
    static func automatic(for date: Date) -> DayType {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 7:  return .saturday
        case 1:  return .sundayOrHoliday
        default: return .weekday
        }
    }

    /// Resolve the effective day type after applying any manual override.
    /// No side effects — safe inside a TimelineProvider.
    static func effective(for date: Date = Date()) -> (dayType: DayType, isManualOverride: Bool) {
        let auto = DayType.automatic(for: date)
        guard let override = SharedStore.readOverride() else {
            return (auto, false)
        }
        if override == auto {
            return (auto, false)
        }
        return (override, true)
    }

    /// Cycle for the override chip's tap action. Skips the auto-matching value
    /// so a tap never produces a no-op.
    static func nextOverrideInCycle(from current: DayType?, currentAuto: DayType) -> DayType? {
        let manualOptions = DayType.allCases.filter { $0 != currentAuto }
        guard manualOptions.count == 2 else { return nil }

        switch current {
        case nil:                    return manualOptions[0]
        case manualOptions[0]:       return manualOptions[1]
        case manualOptions[1]:       return nil
        default:                     return nil
        }
    }
}
