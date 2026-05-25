//
//  LocalBusReminderScheduler.swift
//  Bus_Schedule
//
//  One-shot local notification scheduling for the next visible bus departure.
//

import Combine
import Foundation
import UserNotifications
import BusScheduleCore

@MainActor
final class LocalBusReminderScheduler: ObservableObject {
    struct ActiveReminder: Codable, Equatable, Identifiable, Sendable {
        let id: String
        let locationRawValue: String
        let dayTypeRawValue: String
        let departureTime: String
        let departureTimestamp: TimeInterval
        let triggerTimestamp: TimeInterval
        let leadMinutes: Int
        let createdTimestamp: TimeInterval

        var departureDate: Date {
            Date(timeIntervalSince1970: departureTimestamp)
        }

        var triggerDate: Date {
            Date(timeIntervalSince1970: triggerTimestamp)
        }

        func matches(location: Location, departureDate: Date, referenceDate: Date = Date()) -> Bool {
            locationRawValue == location.rawValue &&
                abs(self.departureDate.timeIntervalSince(departureDate)) < 1 &&
                triggerDate > referenceDate
        }
    }

    enum SchedulingError: Error, LocalizedError {
        case unavailableChoice
        case notificationsDenied

        var errorDescription: String? {
            switch self {
            case .unavailableChoice:
                return BusScheduleStrings.notificationSchedulingFailed
            case .notificationsDenied:
                return BusScheduleStrings.notificationPermissionMessage
            }
        }
    }

    static let identifierPrefix = "bus-schedule.next-departure."

    @Published private(set) var activeReminder: ActiveReminder?

    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let activeReminderKey = "activeNextBusReminder"

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = SharedStore.localDefaults
    ) {
        self.center = center
        self.defaults = defaults
        self.activeReminder = Self.readActiveReminder(from: defaults, key: activeReminderKey)
    }

    func activeReminder(
        matching location: Location,
        departureDate: Date?,
        referenceDate: Date = Date()
    ) -> ActiveReminder? {
        guard let departureDate else { return nil }
        guard let activeReminder,
              activeReminder.matches(
                location: location,
                departureDate: departureDate,
                referenceDate: referenceDate
              ) else {
            return nil
        }
        return activeReminder
    }

    func refresh(referenceDate: Date = Date()) async {
        let pendingIDs = await managedPendingRequestIDs()

        guard let activeReminder else {
            if !pendingIDs.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: pendingIDs)
            }
            return
        }

        if activeReminder.triggerDate <= referenceDate || !pendingIDs.contains(activeReminder.id) {
            center.removePendingNotificationRequests(withIdentifiers: pendingIDs)
            clearActiveReminder()
            return
        }

        let staleIDs = pendingIDs.filter { $0 != activeReminder.id }
        if !staleIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)
        }
    }

    func schedule(choice: BusReminderChoice, location: Location, dayType: DayType) async throws {
        guard let departureTime = choice.departureTime,
              let departureDate = choice.departureDate,
              let triggerDate = choice.triggerDate,
              triggerDate > Date() else {
            throw SchedulingError.unavailableChoice
        }

        try await ensureNotificationAuthorization()

        let existingIDs = await managedPendingRequestIDs()
        if !existingIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: existingIDs)
        }

        let id = Self.identifierPrefix + UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = BusScheduleStrings.campusShuttle
        content.body = BusScheduleStrings.reminderNotificationBody(
            route: WidgetTheme.routeLabel(for: location),
            departureTime: departureTime,
            leadMinutes: choice.leadMinutes
        )
        content.sound = .default
        content.threadIdentifier = "bus-schedule.next-departure"
        content.userInfo = [
            "location": location.rawValue,
            "dayType": dayType.rawValue,
            "departureTime": departureTime,
            "leadMinutes": choice.leadMinutes,
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await center.add(request)

        let active = ActiveReminder(
            id: id,
            locationRawValue: location.rawValue,
            dayTypeRawValue: dayType.rawValue,
            departureTime: departureTime,
            departureTimestamp: departureDate.timeIntervalSince1970,
            triggerTimestamp: triggerDate.timeIntervalSince1970,
            leadMinutes: choice.leadMinutes,
            createdTimestamp: Date().timeIntervalSince1970
        )
        writeActiveReminder(active)
    }

    func cancelActiveReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [activeReminder?.id].compactMap { $0 })
        clearActiveReminder()
    }

    private func ensureNotificationAuthorization() async throws {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { throw SchedulingError.notificationsDenied }
        case .denied:
            throw SchedulingError.notificationsDenied
        @unknown default:
            throw SchedulingError.notificationsDenied
        }
    }

    private func managedPendingRequestIDs() async -> [String] {
        await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
    }

    private func writeActiveReminder(_ reminder: ActiveReminder) {
        guard let data = try? JSONEncoder().encode(reminder) else { return }
        defaults.set(data, forKey: activeReminderKey)
        activeReminder = reminder
    }

    private func clearActiveReminder() {
        defaults.removeObject(forKey: activeReminderKey)
        activeReminder = nil
    }

    private static func readActiveReminder(from defaults: UserDefaults, key: String) -> ActiveReminder? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ActiveReminder.self, from: data)
    }
}
