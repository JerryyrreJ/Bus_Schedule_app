//
//  Types.swift
//  BusScheduleCore
//
//  Core domain types shared across iPhone app, iPhone widget, watchOS app,
//  and watchOS complications. Schedule data is bundled — no remote fetch.
//

import Foundation

public enum Location: String, Sendable {
    case phIINewCampus
    case phIParkingLot
}

public enum DayType: String, CaseIterable, Sendable {
    case weekday
    case saturday
    case sundayOrHoliday
}

public struct BusTime: Identifiable, Sendable {
    public let id: Int
    public let phII: String
    public let phI: String

    public init(id: Int, phII: String, phI: String) {
        self.id = id
        self.phII = phII
        self.phI = phI
    }
}

public enum NextDepartureState: Sendable {
    case scheduled(time: String, departureSecondsFromMidnight: Int)
    case returnImmediately
    case noMoreBuses
}

public enum Schedule {
    public static let weekday: [BusTime] = [
        BusTime(id: 1, phII: "07:30", phI: "Return Immediately"),
        BusTime(id: 2, phII: "07:40", phI: "Return Immediately"),
        BusTime(id: 3, phII: "07:50", phI: "Return Immediately"),
        BusTime(id: 4, phII: "08:10", phI: "Return Immediately"),
        BusTime(id: 5, phII: "08:20", phI: "Return Immediately"),
        BusTime(id: 6, phII: "08:30", phI: "Return Immediately"),
        BusTime(id: 7, phII: "08:40", phI: "Return Immediately"),
        BusTime(id: 8, phII: "08:50", phI: "09:00"),
        BusTime(id: 9, phII: "09:10", phI: "09:30"),
        BusTime(id: 10, phII: "09:40", phI: "10:00"),
        BusTime(id: 11, phII: "10:10", phI: "10:30"),
        BusTime(id: 12, phII: "10:40", phI: "11:00"),
        BusTime(id: 13, phII: "11:10", phI: "11:30"),
        BusTime(id: 14, phII: "11:40", phI: "12:00"),
        BusTime(id: 15, phII: "12:10", phI: "12:30"),
        BusTime(id: 16, phII: "12:40", phI: "13:00"),
        BusTime(id: 17, phII: "13:10", phI: "13:30"),
        BusTime(id: 18, phII: "13:40", phI: "Return Immediately"),
        BusTime(id: 19, phII: "13:50", phI: "Return Immediately"),
        BusTime(id: 20, phII: "14:10", phI: "14:30"),
        BusTime(id: 21, phII: "14:40", phI: "15:00"),
        BusTime(id: 22, phII: "15:10", phI: "15:30"),
        BusTime(id: 23, phII: "15:40", phI: "16:00"),
        BusTime(id: 24, phII: "16:10", phI: "16:30"),
        BusTime(id: 25, phII: "16:40", phI: "17:00"),
        BusTime(id: 26, phII: "17:10", phI: "17:30"),
        BusTime(id: 27, phII: "17:40", phI: "18:00"),
        BusTime(id: 28, phII: "18:10", phI: "18:30"),
        BusTime(id: 29, phII: "18:40", phI: "19:00"),
        BusTime(id: 30, phII: "19:10", phI: "19:30"),
        BusTime(id: 31, phII: "19:40", phI: "20:00"),
        BusTime(id: 32, phII: "20:10", phI: "20:30"),
        BusTime(id: 33, phII: "20:40", phI: "21:00"),
        BusTime(id: 34, phII: "21:10", phI: "21:30"),
        BusTime(id: 35, phII: "21:40", phI: "22:00"),
        BusTime(id: 36, phII: "22:10", phI: "22:30")
    ]

    public static let saturday: [BusTime] = [
        BusTime(id: 1, phII: "07:40", phI: "08:00"),
        BusTime(id: 2, phII: "08:10", phI: "08:30"),
        BusTime(id: 3, phII: "08:20", phI: ""),
        BusTime(id: 4, phII: "08:40", phI: "09:00"),
        BusTime(id: 5, phII: "09:10", phI: "09:30"),
        BusTime(id: 6, phII: "09:40", phI: "10:00"),
        BusTime(id: 7, phII: "10:10", phI: "10:30"),
        BusTime(id: 8, phII: "10:40", phI: "11:10"),
        BusTime(id: 9, phII: "11:20", phI: "11:30"),
        BusTime(id: 10, phII: "11:40", phI: "12:00"),
        BusTime(id: 11, phII: "12:10", phI: "12:30"),
        BusTime(id: 12, phII: "12:40", phI: "13:00"),
        BusTime(id: 13, phII: "13:10", phI: "13:30"),
        BusTime(id: 14, phII: "13:40", phI: "14:00"),
        BusTime(id: 15, phII: "14:10", phI: "14:30"),
        BusTime(id: 16, phII: "14:40", phI: "15:00"),
        BusTime(id: 17, phII: "15:10", phI: "15:30"),
        BusTime(id: 18, phII: "15:40", phI: "16:00"),
        BusTime(id: 19, phII: "16:10", phI: "16:30"),
        BusTime(id: 20, phII: "16:40", phI: "17:00"),
        BusTime(id: 21, phII: "17:10", phI: "17:30"),
        BusTime(id: 22, phII: "17:40", phI: "18:00"),
        BusTime(id: 23, phII: "18:10", phI: "18:30"),
        BusTime(id: 24, phII: "18:40", phI: "19:00"),
        BusTime(id: 25, phII: "19:10", phI: "19:40"),
        BusTime(id: 26, phII: "19:50", phI: "20:00"),
        BusTime(id: 27, phII: "20:10", phI: "20:30"),
        BusTime(id: 28, phII: "20:40", phI: "21:00"),
        BusTime(id: 29, phII: "21:10", phI: "21:30"),
        BusTime(id: 30, phII: "21:40", phI: "22:00"),
        BusTime(id: 31, phII: "22:10", phI: "22:30"),
        BusTime(id: 32, phII: "22:40", phI: "23:00")
    ]

    public static let sundayOrHoliday: [BusTime] = [
        BusTime(id: 1, phII: "07:40", phI: "08:00"),
        BusTime(id: 2, phII: "08:10", phI: "08:30"),
        BusTime(id: 3, phII: "08:40", phI: "09:00"),
        BusTime(id: 4, phII: "09:10", phI: "09:30"),
        BusTime(id: 5, phII: "09:40", phI: "10:00"),
        BusTime(id: 6, phII: "10:10", phI: "10:30"),
        BusTime(id: 7, phII: "10:40", phI: "11:10"),
        BusTime(id: 8, phII: "11:20", phI: "11:30"),
        BusTime(id: 9, phII: "11:40", phI: "12:00"),
        BusTime(id: 10, phII: "12:10", phI: "12:30"),
        BusTime(id: 11, phII: "12:40", phI: "13:00"),
        BusTime(id: 12, phII: "13:10", phI: "13:30"),
        BusTime(id: 13, phII: "13:40", phI: "14:00"),
        BusTime(id: 14, phII: "14:10", phI: "14:30"),
        BusTime(id: 15, phII: "14:40", phI: "15:00"),
        BusTime(id: 16, phII: "15:10", phI: "15:30"),
        BusTime(id: 17, phII: "15:40", phI: "16:00"),
        BusTime(id: 18, phII: "16:10", phI: "16:30"),
        BusTime(id: 19, phII: "16:40", phI: "17:00"),
        BusTime(id: 20, phII: "17:10", phI: "17:30"),
        BusTime(id: 21, phII: "17:40", phI: "18:00"),
        BusTime(id: 22, phII: "18:10", phI: "18:30"),
        BusTime(id: 23, phII: "18:40", phI: "19:00"),
        BusTime(id: 24, phII: "19:10", phI: "19:40"),
        BusTime(id: 25, phII: "19:50", phI: "20:00"),
        BusTime(id: 26, phII: "20:10", phI: "20:30"),
        BusTime(id: 27, phII: "20:40", phI: "21:00"),
        BusTime(id: 28, phII: "21:10", phI: "21:30"),
        BusTime(id: 29, phII: "21:40", phI: "22:00"),
        BusTime(id: 30, phII: "22:10", phI: "22:30"),
        BusTime(id: 31, phII: "22:40", phI: "23:00")
    ]

    public static func getCurrentSchedule(_ dayType: DayType) -> [BusTime] {
        switch dayType {
        case .weekday:         return weekday
        case .saturday:        return saturday
        case .sundayOrHoliday: return sundayOrHoliday
        }
    }

    public static func nextDepartureState(
        for location: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int
    ) -> NextDepartureState {
        let schedule = getCurrentSchedule(dayType)

        if location == .phIParkingLot,
           isReturnImmediatelyActive(in: schedule, currentSecondsFromMidnight: currentSecondsFromMidnight) {
            return .returnImmediately
        }

        for busTime in schedule {
            let timeString = location == .phIINewCampus ? busTime.phII : busTime.phI

            guard let departureSeconds = secondsFromTimeString(timeString),
                  departureSeconds > currentSecondsFromMidnight else {
                continue
            }

            return .scheduled(time: timeString, departureSecondsFromMidnight: departureSeconds)
        }

        return .noMoreBuses
    }

    public static func upcomingDepartures(
        for location: Location,
        dayType: DayType,
        currentSecondsFromMidnight: Int,
        limit: Int = 3
    ) -> [String] {
        let schedule = getCurrentSchedule(dayType)
        var results: [String] = []

        for busTime in schedule {
            let timeString = location == .phIINewCampus ? busTime.phII : busTime.phI

            guard let departureSeconds = secondsFromTimeString(timeString),
                  departureSeconds > currentSecondsFromMidnight else {
                continue
            }

            results.append(timeString)
            if results.count >= limit + 1 {
                break
            }
        }

        return results.count > 1 ? Array(results.dropFirst().prefix(limit)) : []
    }

    private static func isReturnImmediatelyActive(
        in schedule: [BusTime],
        currentSecondsFromMidnight: Int
    ) -> Bool {
        for index in schedule.indices {
            let busTime = schedule[index]

            guard busTime.phI == "Return Immediately",
                  let startSeconds = secondsFromTimeString(busTime.phII),
                  index + 1 < schedule.count,
                  let endSeconds = secondsFromTimeString(schedule[index + 1].phII) else {
                continue
            }

            if currentSecondsFromMidnight >= startSeconds && currentSecondsFromMidnight < endSeconds {
                return true
            }
        }

        return false
    }

    public static func secondsFromTimeString(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":")

        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              (0..<24).contains(hour),
              (0..<60).contains(minute) else {
            return nil
        }

        return (hour * 60 + minute) * 60
    }
}
