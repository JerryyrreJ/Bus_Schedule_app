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
    public static let dayTypeOverrideUpdatedAtKey = "dayTypeOverrideUpdatedAt"
    public static let dayTypeOverrideExpiresAtKey = "dayTypeOverrideExpiresAt"
    public static let dayTypeOverrideSourceDeviceIDKey = "dayTypeOverrideSourceDeviceID"
    public static let primaryRouteKey = "primaryRoute"
    public static let primaryRouteUpdatedAtKey = "primaryRouteUpdatedAt"
    public static let primaryRouteSourceDeviceIDKey = "primaryRouteSourceDeviceID"
    public static let syncDeviceIDKey = "syncDeviceID"

    public static var localDefaults: UserDefaults {
        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        ) != nil else {
            preconditionFailure("App Group container unavailable: \(appGroup)")
        }

        guard let defaults = UserDefaults(suiteName: appGroup) else {
            preconditionFailure("Shared UserDefaults unavailable for App Group: \(appGroup)")
        }

        return defaults
    }

    /// Returns the persisted manual override from the local App Group store
    /// (nil = follow auto). Manual overrides expire at the next local midnight.
    /// Cross-device convergence is handled by WatchConnectivity writing the
    /// latest received state into this store.
    public static func readOverride(for date: Date = Date()) -> DayType? {
        let localValue = localDefaults.string(forKey: dayTypeOverrideKey) ?? ""
        guard !localValue.isEmpty else { return nil }
        guard !isOverrideExpired(for: date) else { return nil }
        return DayType(rawValue: localValue)
    }

    /// Persist a manual override. Pass nil to clear. Writes locally and then
    /// republishes the latest state to the paired Watch when possible.
    public static func writeOverride(_ dayType: DayType?, sourceDate: Date = Date()) {
        let value = dayType?.rawValue ?? ""
        let updatedAt = nextLogicalRevision(after: localOverrideUpdatedAt())
        let expiresAt = dayType.map { _ in nextStartOfDay(after: sourceDate).timeIntervalSince1970 } ?? 0
        applyOverrideValue(
            value,
            updatedAt: updatedAt,
            sourceDeviceID: localDeviceID(),
            expiresAt: expiresAt
        )
        WatchPreferenceSync.shared.publishLocalPreferences()
    }

    /// Returns the user's preferred route from the local App Group store.
    /// Defaults to Phase II -> Phase I when unset.
    public static func readPrimaryRoute() -> Location {
        let localValue = localDefaults.string(forKey: primaryRouteKey) ?? ""
        return Location(rawValue: localValue) ?? .phIINewCampus
    }

    /// Persist the latest chosen route and republish it to the paired device.
    public static func writePrimaryRoute(_ route: Location) {
        let updatedAt = nextLogicalRevision(after: localPrimaryRouteUpdatedAt())
        applyPrimaryRoute(route, updatedAt: updatedAt, sourceDeviceID: localDeviceID())
        WatchPreferenceSync.shared.publishLocalPreferences()
    }

    /// Self-heal the override: if it expired at local midnight, became
    /// redundant, or contains an invalid raw value, drop it. Call from main
    /// apps on launch / foreground / midnight rollover. Don't call from a
    /// TimelineProvider — that's snapshot work, side-effect free.
    public static func selfHealOverride(for date: Date = Date()) {
        let rawValue = localOverrideValue()
        guard !rawValue.isEmpty else { return }

        let auto = DayType.automatic(for: date)
        let storedOverride = DayType(rawValue: rawValue)
        if storedOverride == nil || isOverrideExpired(for: date) || storedOverride == auto {
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

    static func localOverrideUpdatedAt() -> TimeInterval {
        localDefaults.double(forKey: dayTypeOverrideUpdatedAtKey)
    }

    static func localOverrideExpiresAt() -> TimeInterval {
        if localDefaults.object(forKey: dayTypeOverrideExpiresAtKey) != nil {
            return localDefaults.double(forKey: dayTypeOverrideExpiresAtKey)
        }

        let rawValue = localOverrideValue()
        let revision = localOverrideUpdatedAt()
        guard !rawValue.isEmpty, revision > 0 else { return 0 }
        return nextStartOfDay(after: Date(timeIntervalSince1970: revision)).timeIntervalSince1970
    }

    static func localOverrideSourceDeviceID() -> String {
        normalizedSourceDeviceID(
            localDefaults.string(forKey: dayTypeOverrideSourceDeviceIDKey)
        )
    }

    static func localPrimaryRouteValue() -> String {
        localDefaults.string(forKey: primaryRouteKey) ?? Location.phIINewCampus.rawValue
    }

    static func localPrimaryRouteUpdatedAt() -> TimeInterval {
        localDefaults.double(forKey: primaryRouteUpdatedAtKey)
    }

    static func localPrimaryRouteSourceDeviceID() -> String {
        normalizedSourceDeviceID(
            localDefaults.string(forKey: primaryRouteSourceDeviceIDKey)
        )
    }

    static func hasStoredPrimaryRoute() -> Bool {
        localDefaults.string(forKey: primaryRouteKey) != nil
    }

    static func localDeviceID() -> String {
        if let existing = localDefaults.string(forKey: syncDeviceIDKey), !existing.isEmpty {
            return existing
        }

        let generated = UUID().uuidString
        localDefaults.set(generated, forKey: syncDeviceIDKey)
        return generated
    }

    static func writeLocalOverrideValue(_ value: String) {
        localDefaults.set(value, forKey: dayTypeOverrideKey)
    }

    static func writeLocalOverrideValue(
        _ value: String,
        updatedAt: TimeInterval,
        sourceDeviceID: String,
        expiresAt: TimeInterval
    ) {
        localDefaults.set(value, forKey: dayTypeOverrideKey)
        localDefaults.set(updatedAt, forKey: dayTypeOverrideUpdatedAtKey)
        localDefaults.set(sourceDeviceID, forKey: dayTypeOverrideSourceDeviceIDKey)
        localDefaults.set(expiresAt, forKey: dayTypeOverrideExpiresAtKey)
    }

    static func writeLocalPrimaryRoute(_ route: Location, updatedAt: TimeInterval, sourceDeviceID: String) {
        localDefaults.set(route.rawValue, forKey: primaryRouteKey)
        localDefaults.set(updatedAt, forKey: primaryRouteUpdatedAtKey)
        localDefaults.set(sourceDeviceID, forKey: primaryRouteSourceDeviceIDKey)
    }

    @discardableResult
    static func applyOverrideValue(
        _ value: String,
        updatedAt: TimeInterval,
        sourceDeviceID: String,
        expiresAt: TimeInterval
    ) -> Bool {
        let currentValue = localOverrideValue()
        let currentUpdatedAt = localOverrideUpdatedAt()
        let currentSourceDeviceID = localOverrideSourceDeviceID()
        let currentExpiresAt = localOverrideExpiresAt()

        guard currentValue != value ||
              currentUpdatedAt != updatedAt ||
              currentSourceDeviceID != sourceDeviceID ||
              currentExpiresAt != expiresAt else {
            return false
        }

        writeLocalOverrideValue(
            value,
            updatedAt: updatedAt,
            sourceDeviceID: sourceDeviceID,
            expiresAt: expiresAt
        )

        guard currentValue != value else { return false }

        print("[BusSchedule.WCSync] override changed '\(currentValue)' → '\(value)' — reload widgets, post notification")
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .dayTypeOverrideDidChange, object: nil)
        return true
    }

    @discardableResult
    static func applyIncomingOverrideValue(
        _ value: String,
        updatedAt: TimeInterval,
        sourceDeviceID: String,
        expiresAt: TimeInterval
    ) -> Bool {
        if isOverrideExpired(for: Date()) {
            print("[BusSchedule.WCSync] override local expired, accepting incoming '\(value)'@\(updatedAt)#\(sourceDeviceID)")
            return applyOverrideValue(
                value,
                updatedAt: updatedAt,
                sourceDeviceID: sourceDeviceID,
                expiresAt: expiresAt
            )
        }

        let localDecision = compareIncoming(
            incomingRevision: updatedAt,
            incomingSourceDeviceID: sourceDeviceID,
            localRevision: localOverrideUpdatedAt(),
            localSourceDeviceID: localOverrideSourceDeviceID()
        )
        if localDecision < 0 {
            print("[BusSchedule.WCSync] override reject: incoming \(updatedAt)@\(sourceDeviceID) is older than local \(localOverrideUpdatedAt())@\(localOverrideSourceDeviceID())")
            return false
        }
        if localDecision == 0,
           localOverrideValue() == value,
           localOverrideExpiresAt() == expiresAt {
            print("[BusSchedule.WCSync] override reject: revision tie and same value")
            return false
        }

        print("[BusSchedule.WCSync] override apply incoming '\(value)'@\(updatedAt)#\(sourceDeviceID) (was @\(localOverrideUpdatedAt())#\(localOverrideSourceDeviceID()))")
        return applyOverrideValue(
            value,
            updatedAt: updatedAt,
            sourceDeviceID: sourceDeviceID,
            expiresAt: expiresAt
        )
    }

    @discardableResult
    static func applyPrimaryRoute(
        _ route: Location,
        updatedAt: TimeInterval,
        sourceDeviceID: String
    ) -> Bool {
        let currentRoute = readPrimaryRoute()
        let currentUpdatedAt = localPrimaryRouteUpdatedAt()
        let currentSourceDeviceID = localPrimaryRouteSourceDeviceID()

        guard currentRoute != route ||
              currentUpdatedAt != updatedAt ||
              currentSourceDeviceID != sourceDeviceID else {
            return false
        }

        writeLocalPrimaryRoute(route, updatedAt: updatedAt, sourceDeviceID: sourceDeviceID)

        guard currentRoute != route else { return false }

        print("[BusSchedule.WCSync] route changed \(currentRoute.rawValue) → \(route.rawValue) — reload widgets, post notification")
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .primaryRouteDidChange, object: nil)
        return true
    }

    @discardableResult
    static func applyIncomingPrimaryRouteValue(
        _ value: String,
        updatedAt: TimeInterval,
        sourceDeviceID: String
    ) -> Bool {
        guard let route = Location(rawValue: value) else {
            print("[BusSchedule.WCSync] route reject: unknown raw value '\(value)'")
            return false
        }

        let localDecision = compareIncoming(
            incomingRevision: updatedAt,
            incomingSourceDeviceID: sourceDeviceID,
            localRevision: localPrimaryRouteUpdatedAt(),
            localSourceDeviceID: localPrimaryRouteSourceDeviceID()
        )
        if localDecision < 0 {
            print("[BusSchedule.WCSync] route reject: incoming \(updatedAt)@\(sourceDeviceID) is older than local \(localPrimaryRouteUpdatedAt())@\(localPrimaryRouteSourceDeviceID())")
            return false
        }
        if localDecision == 0, hasStoredPrimaryRoute(), readPrimaryRoute() == route {
            print("[BusSchedule.WCSync] route reject: revision tie and same value")
            return false
        }

        print("[BusSchedule.WCSync] route apply incoming \(value)@\(updatedAt)#\(sourceDeviceID) (was @\(localPrimaryRouteUpdatedAt())#\(localPrimaryRouteSourceDeviceID()))")
        return applyPrimaryRoute(route, updatedAt: updatedAt, sourceDeviceID: sourceDeviceID)
    }

    static func nextStartOfDay(after date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(24 * 60 * 60)
    }

    static func isOverrideExpired(for date: Date) -> Bool {
        let expiresAt = localOverrideExpiresAt()
        return expiresAt > 0 && date.timeIntervalSince1970 >= expiresAt
    }

    static func nextLogicalRevision(after current: TimeInterval) -> TimeInterval {
        max(current + 1, 1)
    }

    static func normalizedSourceDeviceID(_ sourceDeviceID: String?) -> String {
        let trimmed = sourceDeviceID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "unknown-device" : trimmed
    }

    static func compareIncoming(
        incomingRevision: TimeInterval,
        incomingSourceDeviceID: String,
        localRevision: TimeInterval,
        localSourceDeviceID: String
    ) -> Int {
        if incomingRevision != localRevision {
            return incomingRevision > localRevision ? 1 : -1
        }

        let normalizedIncoming = normalizedSourceDeviceID(incomingSourceDeviceID)
        let normalizedLocal = normalizedSourceDeviceID(localSourceDeviceID)
        if normalizedIncoming == normalizedLocal { return 0 }
        return normalizedIncoming > normalizedLocal ? 1 : -1
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
        guard let override = SharedStore.readOverride(for: date) else {
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
    private let overrideUpdatedAtPayloadKey = SharedStore.dayTypeOverrideUpdatedAtKey
    private let overrideExpiresAtPayloadKey = SharedStore.dayTypeOverrideExpiresAtKey
    private let overrideSourceDeviceIDPayloadKey = SharedStore.dayTypeOverrideSourceDeviceIDKey
    private let routePayloadKey = SharedStore.primaryRouteKey
    private let routeUpdatedAtPayloadKey = SharedStore.primaryRouteUpdatedAtKey
    private let routeSourceDeviceIDPayloadKey = SharedStore.primaryRouteSourceDeviceIDKey
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
            // Already wired up earlier in this process. If session is now
            // activated, push the latest local state so any value written
            // before activation completed still gets out.
            if session.activationState == .activated {
                publishLocalPreferences()
            }
            return
        }

        // Activation is async — do not call updateApplicationContext or read
        // receivedApplicationContext until activationDidCompleteWith fires.
        // Initial publish + apply-received both happen there.
        session.delegate = self
        session.activate()
        print("[BusSchedule.WCSync] start() called, session.activate() pending")
    }

    func publishLocalPreferences() {
        guard WCSession.isSupported() else { return }
        ensureStartedForSend()

        let payload: [String: Any] = [
            overridePayloadKey: SharedStore.localOverrideValue(),
            overrideUpdatedAtPayloadKey: SharedStore.localOverrideUpdatedAt(),
            overrideExpiresAtPayloadKey: SharedStore.localOverrideExpiresAt(),
            overrideSourceDeviceIDPayloadKey: SharedStore.localOverrideSourceDeviceID(),
            routePayloadKey: SharedStore.localPrimaryRouteValue(),
            routeUpdatedAtPayloadKey: SharedStore.localPrimaryRouteUpdatedAt(),
            routeSourceDeviceIDPayloadKey: SharedStore.localPrimaryRouteSourceDeviceID()
        ]

        #if os(iOS)
        let pairing = "paired=\(session.isPaired) installed=\(session.isWatchAppInstalled)"
        #else
        let pairing = "iosCounterpart=\(session.isCompanionAppInstalled)"
        #endif
        print("[BusSchedule.WCSync] publish state=\(session.activationState.rawValue) \(pairing) route=\(SharedStore.localPrimaryRouteValue())@\(SharedStore.localPrimaryRouteUpdatedAt())#\(SharedStore.localPrimaryRouteSourceDeviceID()) override=\(SharedStore.localOverrideValue())@\(SharedStore.localOverrideUpdatedAt())#\(SharedStore.localOverrideSourceDeviceID()) exp=\(SharedStore.localOverrideExpiresAt())")

        do {
            try session.updateApplicationContext(payload)
        } catch {
            print("[BusSchedule.WCSync] updateApplicationContext threw: \(error)")
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
        print("[BusSchedule.WCSync] activated state=\(activationState.rawValue) error=\(String(describing: error))")
        // Pull anything the counterpart pushed before we were ready, then push
        // our own local state. Doing the publish here (rather than at the end
        // of start()) is what guarantees our value actually reaches the other
        // side — updateApplicationContext throws silently before activation.
        applyReceivedContextIfPresent()
        publishLocalPreferences()
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
        let overrideUpdatedAt: TimeInterval
        if let updatedAt = payload[overrideUpdatedAtPayloadKey] as? TimeInterval {
            overrideUpdatedAt = updatedAt
        } else if let updatedAtNumber = payload[overrideUpdatedAtPayloadKey] as? NSNumber {
            overrideUpdatedAt = updatedAtNumber.doubleValue
        } else {
            overrideUpdatedAt = 0
        }
        let overrideExpiresAt: TimeInterval
        if let expiresAt = payload[overrideExpiresAtPayloadKey] as? TimeInterval {
            overrideExpiresAt = expiresAt
        } else if let expiresAtNumber = payload[overrideExpiresAtPayloadKey] as? NSNumber {
            overrideExpiresAt = expiresAtNumber.doubleValue
        } else {
            overrideExpiresAt = 0
        }
        let overrideSourceDeviceID = SharedStore.normalizedSourceDeviceID(
            payload[overrideSourceDeviceIDPayloadKey] as? String
        )
        let routeValue = payload[routePayloadKey] as? String
        let routeUpdatedAt: TimeInterval
        if let updatedAt = payload[routeUpdatedAtPayloadKey] as? TimeInterval {
            routeUpdatedAt = updatedAt
        } else if let updatedAtNumber = payload[routeUpdatedAtPayloadKey] as? NSNumber {
            routeUpdatedAt = updatedAtNumber.doubleValue
        } else {
            routeUpdatedAt = 0
        }
        let routeSourceDeviceID = SharedStore.normalizedSourceDeviceID(
            payload[routeSourceDeviceIDPayloadKey] as? String
        )

        print("[BusSchedule.WCSync] received route=\(routeValue ?? "nil")@\(routeUpdatedAt)#\(routeSourceDeviceID) override=\(overrideValue ?? "nil")@\(overrideUpdatedAt)#\(overrideSourceDeviceID) exp=\(overrideExpiresAt)")

        DispatchQueue.main.async {
            overrideValue.map {
                SharedStore.applyIncomingOverrideValue(
                    $0,
                    updatedAt: overrideUpdatedAt,
                    sourceDeviceID: overrideSourceDeviceID,
                    expiresAt: overrideExpiresAt
                )
            }
            routeValue.map {
                SharedStore.applyIncomingPrimaryRouteValue(
                    $0,
                    updatedAt: routeUpdatedAt,
                    sourceDeviceID: routeSourceDeviceID
                )
            }
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
