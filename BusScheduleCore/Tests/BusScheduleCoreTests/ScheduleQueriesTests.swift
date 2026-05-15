import Testing
import Foundation
@testable import BusScheduleCore

@Suite("Schedule service start queries")
struct ScheduleQueriesTests {
    @Test("Weekday Phase I service starts with the pickup loop")
    func weekdayPhaseIServiceStartUsesLoop() {
        #expect(
            Schedule.firstServiceStart(for: .phIParkingLot, dayType: .weekday) ==
                .returnImmediately(startTime: "07:30")
        )
        #expect(Schedule.firstDeparture(for: .phIParkingLot, dayType: .weekday) == "09:00")
    }

    @Test("Weekend Phase I service starts with a scheduled departure")
    func weekendPhaseIServiceStartUsesScheduledDeparture() {
        #expect(
            Schedule.firstServiceStart(for: .phIParkingLot, dayType: .saturday) ==
                .scheduled(time: "08:00")
        )
        #expect(
            Schedule.firstServiceStart(for: .phIParkingLot, dayType: .sundayOrHoliday) ==
                .scheduled(time: "08:00")
        )
    }

    @Test("Phase II service start remains the first scheduled departure")
    func phaseIIServiceStartUsesScheduledDeparture() {
        #expect(
            Schedule.firstServiceStart(for: .phIINewCampus, dayType: .weekday) ==
                .scheduled(time: "07:30")
        )
    }

    @Test("No-more-buses refresh targets tomorrow service start")
    func noMoreBusesRefreshUsesTomorrowServiceStart() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 7,
            hour: 23,
            minute: 0
        )))

        let refreshDate = try #require(Schedule.nextInterestingRefreshDate(
            for: .phIParkingLot,
            dayType: .weekday,
            after: date
        ))

        let refreshComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: refreshDate)
        #expect(refreshComponents.year == 2026)
        #expect(refreshComponents.month == 5)
        #expect(refreshComponents.day == 8)
        #expect(refreshComponents.hour == 7)
        #expect(refreshComponents.minute == 30)
    }

    @Test("Circular refresh drops from 1H+ into minute mode at the hour boundary")
    func circularRefreshDropsIntoMinuteModeAtOneHourBoundary() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 7,
            hour: 6,
            minute: 0,
            second: 0
        )))

        let refreshDate = try #require(Schedule.nextInterestingRefreshDate(
            for: .phIINewCampus,
            dayType: .weekday,
            after: date
        ))

        let refreshComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: refreshDate)
        #expect(refreshComponents.year == 2026)
        #expect(refreshComponents.month == 5)
        #expect(refreshComponents.day == 7)
        #expect(refreshComponents.hour == 6)
        #expect(refreshComponents.minute == 30)
        #expect(refreshComponents.second == 1)
    }

    @Test("Wait progress uses the actual gap between previous and next departures")
    func waitProgressUsesActualDepartureGap() {
        let progress = Schedule.waitProgressFraction(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: 9 * 3600
        )

        #expect(progress == 0.5)
    }
}
