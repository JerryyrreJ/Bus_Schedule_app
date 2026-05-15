import Testing
import Foundation
@testable import BusScheduleCore

@Suite("Schedule service start queries")
struct ScheduleQueriesTests {
    private func seconds(_ hour: Int, _ minute: Int, _ second: Int = 0) -> Int {
        ((hour * 60) + minute) * 60 + second
    }

    private func expectScheduled(
        _ state: NextDepartureState,
        time: String,
        seconds: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case let .scheduled(actualTime, actualSeconds) = state else {
            Issue.record("Expected scheduled departure", sourceLocation: sourceLocation)
            return
        }
        #expect(actualTime == time, sourceLocation: sourceLocation)
        #expect(actualSeconds == seconds, sourceLocation: sourceLocation)
    }

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

    @Test("Next departure excludes the current exact departure")
    func nextDepartureExcludesCurrentExactDeparture() {
        let beforeFirst = Schedule.nextDepartureState(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(7, 29, 59)
        )
        expectScheduled(beforeFirst, time: "07:30", seconds: seconds(7, 30))

        let exactlyAtFirst = Schedule.nextDepartureState(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(7, 30)
        )
        expectScheduled(exactlyAtFirst, time: "07:40", seconds: seconds(7, 40))
    }

    @Test("Next departure recognizes Return Immediately interval boundaries")
    func nextDepartureRecognizesReturnImmediatelyBoundaries() {
        let duringLoop = Schedule.nextDepartureState(
            for: .phIParkingLot,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(8, 49, 59)
        )
        guard case .returnImmediately = duringLoop else {
            Issue.record("Expected Return Immediately before the loop boundary")
            return
        }

        let afterLoop = Schedule.nextDepartureState(
            for: .phIParkingLot,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(8, 50)
        )
        expectScheduled(afterLoop, time: "09:00", seconds: seconds(9, 0))
    }

    @Test("Next departure reports no more buses after the final departure")
    func nextDepartureReportsNoMoreBusesAfterFinalDeparture() {
        let finalApproaching = Schedule.nextDepartureState(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(22, 9, 59)
        )
        expectScheduled(finalApproaching, time: "22:10", seconds: seconds(22, 10))

        let afterFinal = Schedule.nextDepartureState(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(22, 10)
        )
        guard case .noMoreBuses = afterFinal else {
            Issue.record("Expected no more buses after the final departure")
            return
        }
    }

    @Test("Upcoming departures skip the active next departure and honor limit")
    func upcomingDeparturesSkipNextAndHonorLimit() {
        #expect(Schedule.upcomingDepartures(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(8, 0),
            limit: 2
        ) == ["08:20", "08:30"])

        #expect(Schedule.upcomingDepartures(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(22, 0),
            limit: 3
        ) == [])

        #expect(Schedule.upcomingDepartures(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(21, 0),
            limit: 1
        ) == ["21:40"])
    }

    @Test("Time parsing rejects malformed or out-of-range values")
    func timeParsingRejectsMalformedValues() {
        #expect(Schedule.secondsFromTimeString("00:00") == 0)
        #expect(Schedule.secondsFromTimeString("23:59") == seconds(23, 59))
        #expect(Schedule.secondsFromTimeString("") == nil)
        #expect(Schedule.secondsFromTimeString("Return Immediately") == nil)
        #expect(Schedule.secondsFromTimeString("24:00") == nil)
        #expect(Schedule.secondsFromTimeString("08:60") == nil)
        #expect(Schedule.secondsFromTimeString("8") == nil)
    }

    @Test("Refresh date advances past Return Immediately deadline")
    func refreshDateAdvancesPastReturnImmediatelyDeadline() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 7,
            hour: 8,
            minute: 45,
            second: 0
        )))

        let refreshDate = try #require(Schedule.nextInterestingRefreshDate(
            for: .phIParkingLot,
            dayType: .weekday,
            after: date
        ))

        let components = calendar.dateComponents([.hour, .minute, .second], from: refreshDate)
        #expect(components.hour == 8)
        #expect(components.minute == 50)
        #expect(components.second == 1)
    }

    @Test("Refresh date follows minute boundary below one hour")
    func refreshDateFollowsMinuteBoundaryBelowOneHour() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 7,
            hour: 6,
            minute: 55,
            second: 10
        )))

        let refreshDate = try #require(Schedule.nextInterestingRefreshDate(
            for: .phIINewCampus,
            dayType: .weekday,
            after: date
        ))

        let components = calendar.dateComponents([.hour, .minute, .second], from: refreshDate)
        #expect(components.hour == 6)
        #expect(components.minute == 56)
        #expect(components.second == 0)
    }

    @Test("Wait progress handles before-first, long-gap, and no-more-buses states")
    func waitProgressHandlesBoundaryStates() {
        #expect(Schedule.waitProgressFraction(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(7, 0)
        ) == 0)

        let fortyMinuteGapProgress = Schedule.waitProgressFraction(
            for: .phIINewCampus,
            dayType: .saturday,
            currentSecondsFromMidnight: seconds(19, 30)
        )
        #expect(abs(fortyMinuteGapProgress - 0.5) < 0.0001)

        #expect(Schedule.waitProgressFraction(
            for: .phIINewCampus,
            dayType: .weekday,
            currentSecondsFromMidnight: seconds(23, 0)
        ) == 0)
    }

    @Test("Sync comparison uses revision first and device ID as tie breaker")
    func syncComparisonUsesRevisionAndDeviceTieBreaker() {
        #expect(SharedStore.compareIncoming(
            incomingRevision: 3,
            incomingSourceDeviceID: "a",
            localRevision: 2,
            localSourceDeviceID: "z"
        ) == 1)

        #expect(SharedStore.compareIncoming(
            incomingRevision: 2,
            incomingSourceDeviceID: "z",
            localRevision: 3,
            localSourceDeviceID: "a"
        ) == -1)

        #expect(SharedStore.compareIncoming(
            incomingRevision: 2,
            incomingSourceDeviceID: "watch",
            localRevision: 2,
            localSourceDeviceID: "phone"
        ) == 1)

        #expect(SharedStore.compareIncoming(
            incomingRevision: 2,
            incomingSourceDeviceID: "phone",
            localRevision: 2,
            localSourceDeviceID: "phone"
        ) == 0)
    }

    @Test("Sync helper normalizes blank device IDs and logical revisions")
    func syncHelpersNormalizeDeviceIDsAndRevisions() {
        #expect(SharedStore.normalizedSourceDeviceID(nil) == "unknown-device")
        #expect(SharedStore.normalizedSourceDeviceID("   ") == "unknown-device")
        #expect(SharedStore.normalizedSourceDeviceID(" phone ") == "phone")

        #expect(SharedStore.nextLogicalRevision(after: -10) == 1)
        #expect(SharedStore.nextLogicalRevision(after: 0) == 1)
        #expect(SharedStore.nextLogicalRevision(after: 4) == 5)
    }

    @Test("Next start of day is local midnight after the reference date")
    func nextStartOfDayUsesLocalMidnightAfterReferenceDate() throws {
        let calendar = Calendar.current
        let date = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 7,
            hour: 23,
            minute: 30
        )))

        let nextStart = SharedStore.nextStartOfDay(after: date)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextStart)
        #expect(components.year == 2026)
        #expect(components.month == 5)
        #expect(components.day == 8)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
}
