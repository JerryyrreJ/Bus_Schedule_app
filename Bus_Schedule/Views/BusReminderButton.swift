import SwiftUI
import UIKit
import BusScheduleCore

struct BusReminderButton: View {
    let location: Location
    let dayType: DayType
    @ObservedObject var scheduler: LocalBusReminderScheduler
    var isCompact: Bool = false

    @Environment(\.openURL) private var openURL
    @State private var isDialogPresented = false
    @State private var alert: ReminderAlert?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let choices = Schedule.reminderChoices(
                for: location,
                dayType: dayType,
                referenceDate: context.date
            )
            let departureDate = choices.compactMap(\.departureDate).first
            let hasScheduledBus = departureDate != nil
            let hasAvailableChoice = choices.contains(where: \.isAvailable)
            let activeReminder = scheduler.activeReminder(
                matching: location,
                departureDate: departureDate,
                referenceDate: context.date
            )
            let isReminderActive = activeReminder != nil
            let canInteract = hasScheduledBus && (hasAvailableChoice || isReminderActive)

            if hasScheduledBus {
                Button {
                    isDialogPresented = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isReminderActive ? "bell.badge.fill" : "bell")
                            .font(.system(size: isCompact ? 14 : 15, weight: .semibold))

                        Text(labelText(activeReminder: activeReminder, hasScheduledBus: hasScheduledBus))
                            .font(.system(size: isCompact ? 13.5 : 14, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(canInteract ? .primary : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, isCompact ? 8 : 10)
                    .background(buttonBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .confirmationDialog(
                    activeReminder == nil ? BusScheduleStrings.remindThisBus : BusScheduleStrings.changeReminder,
                    isPresented: $isDialogPresented,
                    titleVisibility: .visible
                ) {
                    ForEach(choices, id: \.leadMinutes) { choice in
                        Button(BusScheduleStrings.reminderLeadOption(choice.leadMinutes)) {
                            schedule(choice)
                        }
                        .disabled(!choice.isAvailable)
                    }

                    if activeReminder != nil {
                        Button(BusScheduleStrings.cancelReminder, role: .destructive) {
                            scheduler.cancelActiveReminder()
                        }
                    }
                } message: {
                    if hasScheduledBus && !hasAvailableChoice {
                        Text(BusScheduleStrings.reminderTooClose)
                    }
                }
                .alert(item: $alert) { alert in
                    switch alert {
                    case .notificationsDenied:
                        return Alert(
                            title: Text(BusScheduleStrings.notificationsOff),
                            message: Text(BusScheduleStrings.notificationPermissionMessage),
                            primaryButton: .default(Text(BusScheduleStrings.openSettings)) {
                                openSettings()
                            },
                            secondaryButton: .cancel()
                        )
                    case let .schedulingFailed(message):
                        return Alert(
                            title: Text(BusScheduleStrings.notificationSchedulingFailed),
                            message: Text(message),
                            dismissButton: .default(Text(BusScheduleStrings.done))
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
                )
        }
    }

    private func labelText(
        activeReminder: LocalBusReminderScheduler.ActiveReminder?,
        hasScheduledBus: Bool
    ) -> String {
        guard hasScheduledBus else { return BusScheduleStrings.reminderUnavailable }
        guard let activeReminder else { return BusScheduleStrings.remindThisBus }
        return BusScheduleStrings.reminderSet(activeReminder.leadMinutes)
    }

    private func schedule(_ choice: BusReminderChoice) {
        Task {
            do {
                try await scheduler.schedule(choice: choice, location: location, dayType: dayType)
            } catch LocalBusReminderScheduler.SchedulingError.notificationsDenied {
                alert = .notificationsDenied
            } catch {
                alert = .schedulingFailed(
                    error.localizedDescription.isEmpty
                        ? BusScheduleStrings.notificationSchedulingFailed
                        : error.localizedDescription
                )
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private enum ReminderAlert: Identifiable {
    case notificationsDenied
    case schedulingFailed(String)

    var id: String {
        switch self {
        case .notificationsDenied:
            return "notificationsDenied"
        case let .schedulingFailed(message):
            return "schedulingFailed-\(message)"
        }
    }
}

#Preview {
    BusReminderButton(
        location: .phIINewCampus,
        dayType: .weekday,
        scheduler: LocalBusReminderScheduler(defaults: .standard)
    )
    .padding()
}
