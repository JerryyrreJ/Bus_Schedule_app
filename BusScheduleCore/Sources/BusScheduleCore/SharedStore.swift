//
//  SharedStore.swift
//  BusScheduleCore
//
//  App Group-backed persistence for the manual day-type override, plus
//  WatchConnectivity sync between the iPhone app family and the paired Watch.
//  Each device reads/writes its own local App Group store; cross-device sync
//  republishes the latest override state as a watch application context.
//

import Foundation
import WidgetKit
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public enum SharedStore {
    public static let appGroup = "group.Jerry-Lu.Bus-Schedule"
    public static let dayTypeOverrideKey = "dayTypeOverride"
    public static let primaryRouteKey = "primaryRoute"
    public static let primaryRouteUpdatedAtKey = "primaryRouteUpdatedAt"

    public static var localDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Returns the persisted manual override from the local App Group store
    /// (nil = follow auto). Cross-device convergence is handled by
    /// WatchConnectivity writing the latest received state into this store.
    public static func readOverride() -> DayType? {
        let localValue = localDefaults.string(forKey: dayTypeOverrideKey) ?? ""
        return localValue.isEmpty ? nil : DayType(rawValue: localValue)
    }

    /// Persist a manual override. Pass nil to clear. Writes locally and then
    /// republishes the latest state to the paired Watch when possible.
    public static func writeOverride(_ dayType: DayType?) {
        let value = dayType?.rawValue ?? ""
        applyOverrideValue(value)
        WatchPreferenceSync.shared.publishLocalPreferences()
    }

    /// Returns the user's preferred route from the local App Group store.
    /// Defaults to Phase II -> Phase I when unset.
    public static func readPrimaryRoute() -> Location {
        let localValue = localDefaults.string(forKey: primaryRouteKey) ?? ""
        return Location(rawValue: localValue) ?? .phIINewCampus
    }

    /// Persist the latest chosen route and republish it to the paired device.
    public static func writePrimaryRoute(_ route: Location, sourceDate: Date = Date()) {
        let updatedAt = sourceDate.timeIntervalSince1970
        applyPrimaryRoute(route, updatedAt: updatedAt)
        WatchPreferenceSync.shared.publishLocalPreferences()
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

    /// Start cross-device sync via WatchConnectivity. Idempotent — safe to
    /// call from each foreground app's init.
    public static func startWatchSync() {
        WatchPreferenceSync.shared.start()
    }

    static func localOverrideValue() -> String {
        localDefaults.string(forKey: dayTypeOverrideKey) ?? ""
    }

    static func localPrimaryRouteValue() -> String {
        localDefaults.string(forKey: primaryRouteKey) ?? Location.phIINewCampus.rawValue
    }

    static func localPrimaryRouteUpdatedAt() -> TimeInterval {
        localDefaults.double(forKey: primaryRouteUpdatedAtKey)
    }

    static func hasStoredPrimaryRoute() -> Bool {
        localDefaults.string(forKey: primaryRouteKey) != nil
    }

    static func writeLocalOverrideValue(_ value: String) {
        localDefaults.set(value, forKey: dayTypeOverrideKey)
    }

    static func writeLocalPrimaryRoute(_ route: Location, updatedAt: TimeInterval) {
        localDefaults.set(route.rawValue, forKey: primaryRouteKey)
        localDefaults.set(updatedAt, forKey: primaryRouteUpdatedAtKey)
    }

    @discardableResult
    static func applyOverrideValue(_ value: String) -> Bool {
        guard localOverrideValue() != value else { return false }
        writeLocalOverrideValue(value)
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .dayTypeOverrideDidChange, object: nil)
        return true
    }

    @discardableResult
    static func applyPrimaryRoute(_ route: Location, updatedAt: TimeInterval) -> Bool {
        let currentRoute = readPrimaryRoute()
        let currentUpdatedAt = localPrimaryRouteUpdatedAt()

        guard currentRoute != route || currentUpdatedAt != updatedAt else {
            return false
        }

        writeLocalPrimaryRoute(route, updatedAt: updatedAt)

        guard currentRoute != route else { return false }

        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .primaryRouteDidChange, object: nil)
        return true
    }

    @discardableResult
    static func applyIncomingPrimaryRouteValue(_ value: String, updatedAt: TimeInterval) -> Bool {
        guard let route = Location(rawValue: value) else { return false }

        let currentUpdatedAt = localPrimaryRouteUpdatedAt()
        if updatedAt < currentUpdatedAt {
            return false
        }
        if updatedAt == currentUpdatedAt, hasStoredPrimaryRoute() {
            return false
        }

        return applyPrimaryRoute(route, updatedAt: updatedAt)
    }
}

public extension Notification.Name {
    static let dayTypeOverrideDidChange = Notification.Name("BusSchedule.dayTypeOverrideDidChange")
    static let primaryRouteDidChange = Notification.Name("BusSchedule.primaryRouteDidChange")
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

#if canImport(WatchConnectivity)
final class WatchPreferenceSync: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchPreferenceSync()

    private let overridePayloadKey = SharedStore.dayTypeOverrideKey
    private let routePayloadKey = SharedStore.primaryRouteKey
    private let routeUpdatedAtPayloadKey = SharedStore.primaryRouteUpdatedAtKey
    private let session = WCSession.default
    private let lock = NSLock()
    private var didStart = false

    private override init() {
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        lock.lock()
        let alreadyStarted = didStart
        if !alreadyStarted {
            didStart = true
        }
        lock.unlock()

        guard !alreadyStarted else {
            publishLocalPreferences()
            return
        }

        session.delegate = self
        session.activate()
        applyReceivedContextIfPresent()
        publishLocalPreferences()
    }

    func publishLocalPreferences() {
        guard WCSession.isSupported() else { return }
        ensureStartedForSend()

        let payload: [String: Any] = [
            overridePayloadKey: SharedStore.localOverrideValue(),
            routePayloadKey: SharedStore.localPrimaryRouteValue(),
            routeUpdatedAtPayloadKey: SharedStore.localPrimaryRouteUpdatedAt()
        ]

        do {
            try session.updateApplicationContext(payload)
        } catch {
            // Best effort only. The latest state will be republished on the
            // next process launch / activation.
        }

        #if os(iOS)
        if session.isPaired, session.isWatchAppInstalled {
            session.transferCurrentComplicationUserInfo(payload)
        }
        #endif
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        applyReceivedContextIfPresent()
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyPayload(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        applyPayload(userInfo)
    }

    private func ensureStartedForSend() {
        lock.lock()
        let started = didStart
        lock.unlock()

        if !started {
            start()
        }
    }

    private func applyReceivedContextIfPresent() {
        applyPayload(session.receivedApplicationContext)
    }

    private func applyPayload(_ payload: [String: Any]) {
        let overrideValue = payload[overridePayloadKey] as? String
        let routeValue = payload[routePayloadKey] as? String
        let routeUpdatedAt: TimeInterval
        if let updatedAt = payload[routeUpdatedAtPayloadKey] as? TimeInterval {
            routeUpdatedAt = updatedAt
        } else if let updatedAtNumber = payload[routeUpdatedAtPayloadKey] as? NSNumber {
            routeUpdatedAt = updatedAtNumber.doubleValue
        } else {
            routeUpdatedAt = 0
        }

        DispatchQueue.main.async {
            overrideValue.map(SharedStore.applyOverrideValue)
            routeValue.map { SharedStore.applyIncomingPrimaryRouteValue($0, updatedAt: routeUpdatedAt) }
        }
    }
}
#else
final class WatchPreferenceSync: @unchecked Sendable {
    static let shared = WatchPreferenceSync()

    private init() {}

    func start() {}

    func publishLocalPreferences() {}
}
#endif
