//
//  BusReminderChoices.swift
//  BusScheduleCore
//
//  Pure schedule math for one-shot local reminders. The iOS app owns
//  notification permissions and scheduling; core only decides what can be set.
//

import Foundation

public struct BusReminderChoice: Equatable, Sendable {
    public let leadMinutes: Int
    public let departureTime: String?
    public let departureDate: Date?
    public let triggerDate: Date?

    public var isAvailable: Bool {
        triggerDate != nil
    }

    public init(
        leadMinutes: Int,
        departureTime: String?,
        departureDate: Date?,
        triggerDate: Date?
    ) {
        self.leadMinutes = leadMinutes
        self.departureTime = departureTime
        self.departureDate = departureDate
        self.triggerDate = triggerDate
    }
}

public extension Schedule {
    static let defaultReminderLeadMinutes: [Int] = [5, 10, 15]

    static func reminderChoices(
        for location: Location,
        dayType: DayType,
        referenceDate: Date,
        leadMinutes: [Int] = defaultReminderLeadMinutes
    ) -> [BusReminderChoice] {
        let sortedLeadMinutes = leadMinutes.sorted()
        let currentSeconds = secondsFromMidnight(for: referenceDate)

        guard case let .scheduled(time, departureSeconds) = nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) else {
            return sortedLeadMinutes.map {
                BusReminderChoice(
                    leadMinutes: $0,
                    departureTime: nil,
                    departureDate: nil,
                    triggerDate: nil
                )
            }
        }

        let startOfDay = Calendar.current.startOfDay(for: referenceDate)
        let departureDate = startOfDay.addingTimeInterval(TimeInterval(departureSeconds))

        return sortedLeadMinutes.map { minutes in
            let triggerDate = departureDate.addingTimeInterval(-TimeInterval(minutes * 60))
            return BusReminderChoice(
                leadMinutes: minutes,
                departureTime: time,
                departureDate: departureDate,
                triggerDate: triggerDate > referenceDate ? triggerDate : nil
            )
        }
    }
}
