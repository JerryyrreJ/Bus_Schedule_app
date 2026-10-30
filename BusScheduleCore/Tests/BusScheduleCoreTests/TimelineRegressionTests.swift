import Foundation
import Testing
import WidgetKit
@testable import BusScheduleCore

@Suite("Service transitions and complication timelines")
struct TimelineRegressionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Hong_Kong")!
        return calendar
    }

    private func date(day: Int = 7, hour: Int, minute: Int = 0, second: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: day,
                                                        hour: hour, minute: minute, second: second)))
    }

    @Test("Refresh includes morning and afternoon loop starts")
    func loopStartsAreRefreshBoundaries() throws {
        for (hour, minute, expectedHour, expectedMinute) in [(7, 0, 7, 30), (13, 31, 13, 40)] {
            let now = try date(hour: hour, minute: minute)
            let next = try #require(Schedule.nextInterestingRefreshDate(
                for: .phIParkingLot, dayType: .weekday, after: now, calendar: calendar
            ))
            let loopStart = try date(hour: expectedHour, minute: expectedMinute)
            #expect(next <= loopStart) // Earlier minute-countdown refreshes are also valid.
            let timeline = ShuttleProvider.makeComplicationTimeline(from: now, primaryRoute: .phIParkingLot,
                calendar: calendar, resolveDayType: { _ in (.weekday, false) })
            #expect(timeline.entries.contains { $0.date == loopStart })
            let before = Schedule.nextDepartureState(for: .phIParkingLot, dayType: .weekday,
                currentSecondsFromMidnight: Schedule.secondsFromMidnight(for: loopStart.addingTimeInterval(-1), calendar: calendar))
            if case .returnImmediately = before { Issue.record("Loop began before its boundary") }
            let atBoundary = Schedule.circularComplicationState(for: .phIParkingLot, dayType: .weekday,
                                                               at: loopStart, calendar: calendar)
            guard case .returnImmediately = atBoundary else { Issue.record("Loop did not begin at boundary"); return }
        }
    }

    @Test("Refresh does not wait a second after loop end or departure")
    func exactServiceBoundaries() throws {
        let loopEnd = try #require(Schedule.nextInterestingRefreshDate(
            for: .phIParkingLot, dayType: .weekday, after: date(hour: 8, minute: 49, second: 59), calendar: calendar
        ))
        #expect(loopEnd == (try date(hour: 8, minute: 50)))
        let departure = try #require(Schedule.nextInterestingRefreshDate(
            for: .phIINewCampus, dayType: .weekday, after: date(hour: 9, minute: 9, second: 59), calendar: calendar
        ))
        #expect(departure == (try date(hour: 9, minute: 10)))
    }

    @Test("Timeline includes the departure and requests renewal when its entries end")
    func timelineCoversDepartureAndRenews() throws {
        let now = try date(hour: 9)
        let timeline = ShuttleProvider.makeComplicationTimeline(from: now, primaryRoute: .phIINewCampus,
            calendar: calendar, resolveDayType: { _ in (.weekday, false) })
        let departure = try date(hour: 9, minute: 10)
        let entry = try #require(timeline.entries.first { $0.date == departure })
        let next = Schedule.nextScheduledDeparture(for: entry.primaryRoute, dayType: entry.dayType,
            currentSecondsFromMidnight: Schedule.secondsFromMidnight(for: entry.date, calendar: calendar))
        #expect(next?.time == "09:40")
        #expect(timeline.entries.count <= 60)
        #expect(try #require(timeline.entries.last).date < now.addingTimeInterval(6 * 3600))
        switch timeline.policy {
        case .atEnd: break
        default: Issue.record("Timeline must renew when its last entry is consumed")
        }
    }

    @Test("All route/day timelines advance strictly and have a renewal policy", arguments: DayType.allCases)
    func allTimelinesAdvance(dayType: DayType) throws {
        for location in [Location.phIINewCampus, .phIParkingLot] {
            let now = try date(hour: 7)
            let timeline = ShuttleProvider.makeComplicationTimeline(from: now, primaryRoute: location,
                calendar: calendar, resolveDayType: { _ in (dayType, false) })
            #expect(timeline.entries.first?.date == now)
            #expect(timeline.entries.count > 1)
            #expect(timeline.entries.count <= 60)
            for (earlier, later) in zip(timeline.entries, timeline.entries.dropFirst()) {
                #expect(later.date > earlier.date)
            }
            switch timeline.policy {
            case .atEnd: break
            default: Issue.record("Uncovered interval after timeline end")
            }
        }
    }

    @Test("Midnight re-resolves an expiring manual override in the generated timeline")
    func midnightReResolvesOverride() throws {
        let now = try date(day: 10, hour: 23, minute: 30) // Sunday forced to Saturday.
        let midnight = try date(day: 11, hour: 0)
        let timeline = ShuttleProvider.makeComplicationTimeline(from: now, primaryRoute: .phIINewCampus,
            calendar: calendar, resolveDayType: { date in
                date < midnight ? (.saturday, true) : (DayType.automatic(for: date, calendar: calendar), false)
            })
        let nextDayEntry = try #require(timeline.entries.first { $0.date == midnight })
        #expect(nextDayEntry.dayType == .weekday)
        #expect(!nextDayEntry.isManualOverride)
        let tomorrow = Schedule.nextServiceDay(after: now, currentDayType: .saturday,
                                               isManualOverride: true, calendar: calendar)
        #expect(tomorrow.dayType == nextDayEntry.dayType)
        #expect(Schedule.firstDeparture(for: .phIINewCampus, dayType: tomorrow.dayType) == "07:30")
    }

    @Test("Tomorrow calculation crosses year end and month end")
    func calendarRollovers() throws {
        for (year, month, day, nextYear, nextMonth, nextDay) in [(2026, 12, 31, 2027, 1, 1), (2026, 2, 28, 2026, 3, 1)] {
            let now = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 23)))
            let next = Schedule.nextServiceDay(after: now, currentDayType: .saturday,
                                               isManualOverride: true, calendar: calendar)
            let components = calendar.dateComponents([.year, .month, .day], from: next.date)
            #expect(components.year == nextYear)
            #expect(components.month == nextMonth)
            #expect(components.day == nextDay)
        }
    }

    @Test("Reminder departure uses wall clock time on a daylight-saving transition")
    func reminderUsesCalendarTimeAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 6)))
        let choices = Schedule.reminderChoices(for: .phIINewCampus, dayType: .weekday,
                                              referenceDate: now, calendar: calendar)
        let departure = try #require(choices.first?.departureDate)
        let parts = calendar.dateComponents([.hour, .minute], from: departure)
        #expect(parts.hour == 7)
        #expect(parts.minute == 30)
    }

    @Test("Bundled schedules are ordered and queries skip blank/loop cells", arguments: DayType.allCases)
    func bundledScheduleInvariants(dayType: DayType) throws {
        for location in [Location.phIINewCampus, .phIParkingLot] {
            let rows = Schedule.getCurrentSchedule(dayType)
            let times = rows.compactMap { Schedule.secondsFromTimeString(location == .phIINewCampus ? $0.phII : $0.phI) }
            #expect(!times.isEmpty)
            #expect(Set(times).count == times.count)
            #expect(times == times.sorted())
            for time in times {
                let before = try #require(Schedule.nextScheduledDeparture(for: location, dayType: dayType,
                                                                          currentSecondsFromMidnight: time - 1))
                #expect(before.departureSecondsFromMidnight == time)
                let after = Schedule.nextScheduledDeparture(for: location, dayType: dayType,
                                                            currentSecondsFromMidnight: time)
                #expect(after == nil || after!.departureSecondsFromMidnight > time)
                #expect(Schedule.previousDepartureSeconds(for: location, dayType: dayType,
                                                          currentSecondsFromMidnight: time) == time)
            }
        }
    }
}
