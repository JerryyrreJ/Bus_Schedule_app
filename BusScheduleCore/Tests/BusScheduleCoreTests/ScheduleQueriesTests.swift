import Testing
import Foundation
@testable import BusScheduleCore

@Suite("Schedule service start queries")
struct ScheduleQueriesTests {
    // Exercise the public local-time defaults without inheriting the user's calendar system.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func seconds(_ hour: Int, _ minute: Int, _ second: Int = 0) -> Int {
        ((hour * 60) + minute) * 60 + second
    }

    private func localDate(
        year: Int = 2026,
        month: Int = 5,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
        second: Int = 0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )), sourceLocation: sourceLocation)
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

    @Test("No-more-buses refresh re-resolves service at midnight")
    func noMoreBusesRefreshUsesMidnight() throws {
        let calendar = self.calendar
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
        #expect(refreshComponents.hour == 0)
        #expect(refreshComponents.minute == 0)
    }

    @Test("Circular refresh drops from 1H+ into minute mode at the hour boundary")
    func circularRefreshDropsIntoMinuteModeAtOneHourBoundary() throws {
        let calendar = self.calendar
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

    @Test("Refresh date reaches Return Immediately deadline")
    func refreshDateReachesReturnImmediatelyDeadline() throws {
        let calendar = self.calendar
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
        #expect(components.second == 0)
    }

    @Test("Refresh date follows minute boundary below one hour")
    func refreshDateFollowsMinuteBoundaryBelowOneHour() throws {
        let calendar = self.calendar
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

    @Test("Automatic day type follows local calendar weekday")
    func automaticDayTypeFollowsCalendarWeekday() throws {
        #expect(DayType.automatic(for: try localDate(day: 4)) == .weekday)
        #expect(DayType.automatic(for: try localDate(day: 9)) == .saturday)
        #expect(DayType.automatic(for: try localDate(day: 10)) == .sundayOrHoliday)
    }

    @Test("Override cycle skips the automatic day type")
    func overrideCycleSkipsAutomaticDayType() {
        #expect(DayType.nextOverrideInCycle(from: nil, currentAuto: .weekday) == .saturday)
        #expect(DayType.nextOverrideInCycle(from: .saturday, currentAuto: .weekday) == .sundayOrHoliday)
        #expect(DayType.nextOverrideInCycle(from: .sundayOrHoliday, currentAuto: .weekday) == nil)

        #expect(DayType.nextOverrideInCycle(from: nil, currentAuto: .saturday) == .weekday)
        #expect(DayType.nextOverrideInCycle(from: .weekday, currentAuto: .saturday) == .sundayOrHoliday)
        #expect(DayType.nextOverrideInCycle(from: .sundayOrHoliday, currentAuto: .saturday) == nil)

        #expect(DayType.nextOverrideInCycle(from: nil, currentAuto: .sundayOrHoliday) == .weekday)
        #expect(DayType.nextOverrideInCycle(from: .weekday, currentAuto: .sundayOrHoliday) == .saturday)
        #expect(DayType.nextOverrideInCycle(from: .saturday, currentAuto: .sundayOrHoliday) == nil)
    }

    @Test("Next service day uses automatic type after override expiration")
    func nextServiceDayUsesAutomaticTypeAfterOverrideExpiration() throws {
        let friday = try localDate(day: 8, hour: 23)

        let manual = Schedule.nextServiceDay(
            after: friday,
            currentDayType: .weekday,
            isManualOverride: true
        )
        #expect(manual.dayType == .saturday)

        let automatic = Schedule.nextServiceDay(
            after: friday,
            currentDayType: .weekday,
            isManualOverride: false
        )
        #expect(automatic.dayType == .saturday)

        let manualComponents = calendar.dateComponents([.year, .month, .day], from: manual.date)
        let automaticComponents = calendar.dateComponents([.year, .month, .day], from: automatic.date)
        #expect(manualComponents.year == 2026)
        #expect(manualComponents.month == 5)
        #expect(manualComponents.day == 9)
        #expect(automaticComponents.year == 2026)
        #expect(automaticComponents.month == 5)
        #expect(automaticComponents.day == 9)
    }

    @Test("Last departure returns final scheduled bus for weekday and weekend")
    func lastDepartureReturnsFinalScheduledBus() {
        #expect(Schedule.lastDeparture(for: .phIINewCampus, dayType: .weekday) == "22:10")
        #expect(Schedule.lastDeparture(for: .phIParkingLot, dayType: .weekday) == "22:30")
        #expect(Schedule.lastDeparture(for: .phIINewCampus, dayType: .saturday) == "22:40")
        #expect(Schedule.lastDeparture(for: .phIParkingLot, dayType: .sundayOrHoliday) == "23:00")
    }

    @Test("Countdown formatter covers immediate seconds minutes and hours")
    func countdownFormatterCoversDisplayModes() {
        #expect(CountdownFormatter.string(forSeconds: 0) == BusScheduleStrings.now)
        #expect(CountdownFormatter.string(forSeconds: -1) == BusScheduleStrings.now)
        #expect(CountdownFormatter.string(forSeconds: 45) == "45s")
        #expect(CountdownFormatter.string(forSeconds: 185) == "3m 05s")
        #expect(CountdownFormatter.string(forSeconds: 300) == "5m 00s")
        #expect(CountdownFormatter.string(forSeconds: 301) == "5m")
        #expect(CountdownFormatter.string(forSeconds: 720) == "12m")
        #expect(CountdownFormatter.string(forSeconds: 3600) == "1h")
        #expect(CountdownFormatter.string(forSeconds: 3660) == "1h 1m")
    }

    @Test("Widget urgency changes at three and five minute boundaries")
    func widgetUrgencyBoundaryValues() {
        #expect(WidgetUrgency.from(secondsRemaining: seconds(0, 3)) == .critical)
        #expect(WidgetUrgency.from(secondsRemaining: seconds(0, 3, 1)) == .warm)
        #expect(WidgetUrgency.from(secondsRemaining: seconds(0, 5)) == .warm)
        #expect(WidgetUrgency.from(secondsRemaining: seconds(0, 5, 1)) == .normal)
    }

    @Test("Reminder choices expose all default lead times for a scheduled bus")
    func reminderChoicesExposeDefaultLeadTimes() throws {
        let date = try localDate(day: 7, hour: 7, minute: 50)
        let choices = Schedule.reminderChoices(
            for: .phIINewCampus,
            dayType: .weekday,
            referenceDate: date
        )

        #expect(choices.map(\.leadMinutes) == [5, 10, 15])
        #expect(choices.allSatisfy { $0.isAvailable })
        #expect(choices.allSatisfy { $0.departureTime == "08:10" })

        let calendar = self.calendar
        let triggerComponents = try choices.map {
            calendar.dateComponents([.hour, .minute], from: try #require($0.triggerDate))
        }
        #expect(triggerComponents.map(\.hour) == [8, 8, 7])
        #expect(triggerComponents.map(\.minute) == [5, 0, 55])
    }

    @Test("Reminder choices disable lead times that cannot still fire")
    func reminderChoicesDisableTooLateLeadTimes() throws {
        let date = try localDate(day: 7, hour: 8, minute: 6, second: 0)
        let choices = Schedule.reminderChoices(
            for: .phIINewCampus,
            dayType: .weekday,
            referenceDate: date
        )

        #expect(choices.map(\.leadMinutes) == [5, 10, 15])
        #expect(choices.map(\.isAvailable) == [false, false, false])
        #expect(choices.allSatisfy { $0.departureTime == "08:10" })
        #expect(choices.allSatisfy { $0.departureDate != nil })
    }

    @Test("Reminder choices reject exact trigger boundary")
    func reminderChoicesRejectExactTriggerBoundary() throws {
        let date = try localDate(day: 7, hour: 8, minute: 0, second: 0)
        let choices = Schedule.reminderChoices(
            for: .phIINewCampus,
            dayType: .weekday,
            referenceDate: date,
            leadMinutes: [10]
        )

        #expect(choices.count == 1)
        #expect(choices[0].departureTime == "08:10")
        #expect(choices[0].triggerDate == nil)
        #expect(!choices[0].isAvailable)
    }

    @Test("Reminder choices are unavailable during loop and after service")
    func reminderChoicesUnavailableWhenNoScheduledNextBus() throws {
        let loopDate = try localDate(day: 7, hour: 8, minute: 45)
        let loopChoices = Schedule.reminderChoices(
            for: .phIParkingLot,
            dayType: .weekday,
            referenceDate: loopDate
        )
        #expect(loopChoices.allSatisfy { !$0.isAvailable })
        #expect(loopChoices.allSatisfy { $0.departureDate == nil })

        let afterServiceDate = try localDate(day: 7, hour: 23, minute: 0)
        let afterServiceChoices = Schedule.reminderChoices(
            for: .phIINewCampus,
            dayType: .weekday,
            referenceDate: afterServiceDate
        )
        #expect(afterServiceChoices.allSatisfy { !$0.isAvailable })
        #expect(afterServiceChoices.allSatisfy { $0.departureDate == nil })
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
        let calendar = self.calendar
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

