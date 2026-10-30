// iOS notification adapter and observable state for the shared reminder coordinator.
import Combine
import Foundation
import UserNotifications
import BusScheduleCore

@MainActor
final class LocalBusReminderScheduler: ObservableObject {
    typealias ActiveReminder = BusReminderScheduler.ActiveReminder
    typealias SchedulingError = BusReminderScheduler.SchedulingError

    @Published private(set) var activeReminder: ActiveReminder?
    private let scheduler: BusReminderScheduler

    init(center: UNUserNotificationCenter = .current(), defaults: UserDefaults = SharedStore.localDefaults) {
        scheduler = BusReminderScheduler(center: SystemBusReminderNotificationCenter(center: center), defaults: defaults)
        activeReminder = scheduler.activeReminder
    }

    func activeReminder(matching location: Location, departureDate: Date?, referenceDate: Date = Date()) -> ActiveReminder? {
        scheduler.activeReminder(matching: location, departureDate: departureDate, referenceDate: referenceDate)
    }

    func refresh(referenceDate: Date = Date()) async {
        await scheduler.refresh(referenceDate: referenceDate)
        activeReminder = scheduler.activeReminder
    }

    func schedule(choice: BusReminderChoice, location: Location, dayType: DayType) async throws {
        defer { activeReminder = scheduler.activeReminder }
        try await scheduler.schedule(choice: choice, location: location, dayType: dayType)
    }

    func cancelActiveReminder() {
        scheduler.cancelActiveReminder()
        activeReminder = scheduler.activeReminder
    }
}

@MainActor
private final class SystemBusReminderNotificationCenter: BusReminderNotificationCenter {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter) { self.center = center }

    func ensureAuthorization() async throws {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { throw BusReminderScheduler.SchedulingError.notificationsDenied }
        case .denied:
            throw BusReminderScheduler.SchedulingError.notificationsDenied
        @unknown default:
            throw BusReminderScheduler.SchedulingError.notificationsDenied
        }
    }

    func pendingReminderIDs() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(BusReminderScheduler.identifierPrefix) }
    }

    func addReminder(id: String, choice: BusReminderChoice, location: Location, dayType: DayType) async throws {
        guard let departureTime = choice.departureTime, let triggerDate = choice.triggerDate else {
            throw BusReminderScheduler.SchedulingError.unavailableChoice
        }
        let content = UNMutableNotificationContent()
        content.title = BusScheduleStrings.campusShuttle
        content.body = BusScheduleStrings.reminderNotificationBody(
            route: WidgetTheme.routeLabel(for: location), departureTime: departureTime, leadMinutes: choice.leadMinutes
        )
        content.sound = .default
        content.threadIdentifier = "bus-schedule.next-departure"
        content.userInfo = ["location": location.rawValue, "dayType": dayType.rawValue,
                            "departureTime": departureTime, "leadMinutes": choice.leadMinutes]
        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: triggerDate
        )
        components.timeZone = Calendar.current.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func removeReminders(withIDs ids: [String]) {
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
