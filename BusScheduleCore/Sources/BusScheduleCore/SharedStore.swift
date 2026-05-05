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
        writeLocalOverrideValue(value)
        WatchOverrideSync.shared.publishLocalOverride()
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
        WatchOverrideSync.shared.start()
    }

    static func localOverrideValue() -> String {
        localDefaults.string(forKey: dayTypeOverrideKey) ?? ""
    }

    static func writeLocalOverrideValue(_ value: String) {
        localDefaults.set(value, forKey: dayTypeOverrideKey)
    }

    static func applyIncomingOverrideValue(_ value: String) {
        guard localOverrideValue() != value else { return }
        writeLocalOverrideValue(value)
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .dayTypeOverrideDidChange, object: nil)
    }
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

#if canImport(WatchConnectivity)
final class WatchOverrideSync: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchOverrideSync()

    private let payloadKey = SharedStore.dayTypeOverrideKey
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
            publishLocalOverride()
            return
        }

        session.delegate = self
        session.activate()
        applyReceivedContextIfPresent()
        publishLocalOverride()
    }

    func publishLocalOverride() {
        guard WCSession.isSupported() else { return }
        ensureStartedForSend()

        let payload = [payloadKey: SharedStore.localOverrideValue()]

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
        guard let value = payload[payloadKey] as? String else { return }
        DispatchQueue.main.async {
            SharedStore.applyIncomingOverrideValue(value)
        }
    }
}
#else
final class WatchOverrideSync {
    static let shared = WatchOverrideSync()

    private init() {}

    func start() {}

    func publishLocalOverride() {}
}
#endif
