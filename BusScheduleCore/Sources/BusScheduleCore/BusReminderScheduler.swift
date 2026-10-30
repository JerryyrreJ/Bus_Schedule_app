import Foundation

/// The app supplies the system notification adapter; tests supply a deterministic fake.
@MainActor
public protocol BusReminderNotificationCenter {
    func ensureAuthorization() async throws
    func pendingReminderIDs() async -> [String]
    func addReminder(id: String, choice: BusReminderChoice, location: Location, dayType: DayType) async throws
    func removeReminders(withIDs ids: [String])
}

@MainActor
public final class BusReminderScheduler {
    public struct ActiveReminder: Codable, Equatable, Identifiable, Sendable {
        public let id: String
        public let locationRawValue: String
        public let dayTypeRawValue: String
        public let departureTime: String
        public let departureTimestamp: TimeInterval
        public let triggerTimestamp: TimeInterval
        public let leadMinutes: Int
        public let createdTimestamp: TimeInterval

        public var departureDate: Date { Date(timeIntervalSince1970: departureTimestamp) }
        public var triggerDate: Date { Date(timeIntervalSince1970: triggerTimestamp) }

        public func matches(location: Location, departureDate: Date, referenceDate: Date = Date()) -> Bool {
            locationRawValue == location.rawValue &&
                abs(self.departureDate.timeIntervalSince(departureDate)) < 1 &&
                triggerDate > referenceDate
        }
    }

    public enum SchedulingError: Error, LocalizedError {
        case unavailableChoice
        case notificationsDenied
        case operationInProgress

        public var errorDescription: String? {
            switch self {
            case .unavailableChoice, .operationInProgress:
                return BusScheduleStrings.notificationSchedulingFailed
            case .notificationsDenied:
                return BusScheduleStrings.notificationPermissionMessage
            }
        }
    }

    public static let identifierPrefix = "bus-schedule.next-departure."
    public private(set) var activeReminder: ActiveReminder?

    private let center: any BusReminderNotificationCenter
    private let defaults: UserDefaults
    private let now: () -> Date
    private let activeReminderKey = "activeNextBusReminder"
    private var isScheduling = false
    private var operationVersion: UInt64 = 0

    public init(center: any BusReminderNotificationCenter, defaults: UserDefaults,
                now: @escaping () -> Date = Date.init) {
        self.center = center
        self.defaults = defaults
        self.now = now
        if let data = defaults.data(forKey: activeReminderKey) {
            self.activeReminder = try? JSONDecoder().decode(ActiveReminder.self, from: data)
        }
    }

    public func activeReminder(matching location: Location, departureDate: Date?,
                               referenceDate: Date = Date()) -> ActiveReminder? {
        guard let departureDate, let activeReminder,
              activeReminder.matches(location: location, departureDate: departureDate,
                                     referenceDate: referenceDate) else { return nil }
        return activeReminder
    }

    public func refresh(referenceDate: Date = Date()) async {
        guard !isScheduling else { return }
        let version = operationVersion
        let pendingIDs = await center.pendingReminderIDs()
        // A schedule/cancel may have happened while the system request was suspended.
        guard !isScheduling, version == operationVersion else { return }
        guard let activeReminder else {
            center.removeReminders(withIDs: pendingIDs)
            return
        }
        if activeReminder.triggerDate <= referenceDate || !pendingIDs.contains(activeReminder.id) {
            center.removeReminders(withIDs: pendingIDs)
            clearActiveReminder()
        } else {
            center.removeReminders(withIDs: pendingIDs.filter { $0 != activeReminder.id })
        }
    }

    public func schedule(choice: BusReminderChoice, location: Location, dayType: DayType) async throws {
        guard !isScheduling else { throw SchedulingError.operationInProgress }
        isScheduling = true
        operationVersion &+= 1
        let version = operationVersion
        defer { isScheduling = false }

        try validate(choice, version: version)
        try await center.ensureAuthorization()
        try validate(choice, version: version)
        let existingIDs = await center.pendingReminderIDs()
        try validate(choice, version: version)

        let id = Self.identifierPrefix + UUID().uuidString
        guard let departureTime = choice.departureTime,
              let departureDate = choice.departureDate,
              let triggerDate = choice.triggerDate else { throw SchedulingError.unavailableChoice }
        let active = ActiveReminder(
            id: id, locationRawValue: location.rawValue, dayTypeRawValue: dayType.rawValue,
            departureTime: departureTime, departureTimestamp: departureDate.timeIntervalSince1970,
            triggerTimestamp: triggerDate.timeIntervalSince1970, leadMinutes: choice.leadMinutes,
            createdTimestamp: now().timeIntervalSince1970
        )
        // Prepare persistence before adding so encoding failure cannot leave an orphan.
        let data = try JSONEncoder().encode(active)
        do {
            // Add the replacement before deleting the old request. A failed add
            // must leave both the old pending request and persisted state intact.
            try await center.addReminder(id: id, choice: choice, location: location, dayType: dayType)
            try validate(choice, version: version)
        } catch {
            center.removeReminders(withIDs: [id])
            throw error
        }

        defaults.set(data, forKey: activeReminderKey)
        activeReminder = active
        center.removeReminders(withIDs: existingIDs.filter { $0 != id })
    }

    public func cancelActiveReminder() {
        operationVersion &+= 1 // Also invalidates a request currently awaiting permission/add.
        center.removeReminders(withIDs: [activeReminder?.id].compactMap { $0 })
        clearActiveReminder()
    }

    private func validate(_ choice: BusReminderChoice, version: UInt64) throws {
        try Task.checkCancellation()
        guard version == operationVersion else { throw CancellationError() }
        guard choice.departureTime != nil, choice.departureDate != nil,
              let triggerDate = choice.triggerDate, triggerDate > now() else {
            throw SchedulingError.unavailableChoice
        }
    }

    private func clearActiveReminder() {
        defaults.removeObject(forKey: activeReminderKey)
        activeReminder = nil
    }
}
