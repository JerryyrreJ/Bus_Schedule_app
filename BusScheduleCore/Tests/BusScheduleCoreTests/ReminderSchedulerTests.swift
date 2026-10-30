import Foundation
import Testing
@testable import BusScheduleCore

@MainActor
private final class FakeReminderCenter: BusReminderNotificationCenter {
    enum Failure: Error { case adding }
    var pending: Set<String> = []
    var failAdd = false
    var denyPermission = false
    var onAuthorization: (() -> Void)?
    var onPending: (() -> Void)?
    var onAdd: (() -> Void)?
    var duringAdd: (@MainActor () async -> Void)?
    var added: [String] = []
    var removed: [String] = []

    func ensureAuthorization() async throws {
        onAuthorization?()
        if denyPermission { throw BusReminderScheduler.SchedulingError.notificationsDenied }
    }
    func pendingReminderIDs() async -> [String] {
        onPending?()
        return Array(pending)
    }
    func addReminder(id: String, choice: BusReminderChoice, location: Location, dayType: DayType) async throws {
        if failAdd { throw Failure.adding }
        pending.insert(id)
        added.append(id)
        onAdd?()
        await duringAdd?()
    }
    func removeReminders(withIDs ids: [String]) {
        removed.append(contentsOf: ids)
        pending.subtract(ids)
    }
}

@MainActor
private final class ReminderFixture {
    let suiteName = "BusScheduleTests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let center = FakeReminderCenter()
    var now = Date(timeIntervalSince1970: 1_800_000_000)
    lazy var scheduler = BusReminderScheduler(center: center, defaults: defaults, now: { [unowned self] in self.now })

    init() { defaults = UserDefaults(suiteName: suiteName)! }
    func cleanUp() { defaults.removePersistentDomain(forName: suiteName) }
    func choice(after seconds: TimeInterval = 300) -> BusReminderChoice {
        BusReminderChoice(leadMinutes: 5, departureTime: "08:10",
                          departureDate: now.addingTimeInterval(seconds + 300),
                          triggerDate: now.addingTimeInterval(seconds))
    }
    func schedule(_ choice: BusReminderChoice) async throws {
        try await scheduler.schedule(choice: choice, location: .phIINewCampus, dayType: .weekday)
    }
}

@Suite("Reminder scheduling transactions")
@MainActor
struct ReminderSchedulerTests {
    @Test("Authorization delay expires the choice without deleting the old reminder")
    func authorizationDelayPreservesOldReminder() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice(after: 3600))
        let old = try #require(f.scheduler.activeReminder)
        let choice = f.choice(after: 60)
        f.center.onAuthorization = { f.now = choice.triggerDate! }
        do { try await f.schedule(choice); Issue.record("Expired choice was scheduled") }
        catch BusReminderScheduler.SchedulingError.unavailableChoice { }
        #expect(f.scheduler.activeReminder == old)
        #expect(f.center.pending == [old.id])
        #expect(f.center.added.count == 1)
    }

    @Test("Pending-request lookup delay is checked before adding")
    func pendingLookupDelay() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        let choice = f.choice(after: 60)
        f.center.onPending = { f.now = choice.triggerDate! }
        do { try await f.schedule(choice); Issue.record("Expired choice was added") }
        catch BusReminderScheduler.SchedulingError.unavailableChoice { }
        #expect(f.center.added.isEmpty)
        #expect(f.scheduler.activeReminder == nil)
    }

    @Test("Failed replacement preserves the pending and persisted old reminder")
    func failedReplacementKeepsOldReminder() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice())
        let old = try #require(f.scheduler.activeReminder)
        f.center.failAdd = true
        do { try await f.schedule(f.choice(after: 600)); Issue.record("Expected add failure") }
        catch FakeReminderCenter.Failure.adding { }
        #expect(f.scheduler.activeReminder == old)
        #expect(f.center.pending == [old.id])
        let restored = BusReminderScheduler(center: f.center, defaults: f.defaults)
        #expect(restored.activeReminder == old)
    }

    @Test("Successful replacement removes old requests after the new add succeeds")
    func successfulReplacement() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice())
        let old = try #require(f.scheduler.activeReminder)
        var oldWasPresentAtAdd = false
        f.center.onAdd = { oldWasPresentAtAdd = f.center.pending.contains(old.id) }
        try await f.schedule(f.choice(after: 600))
        let new = try #require(f.scheduler.activeReminder)
        #expect(oldWasPresentAtAdd)
        #expect(new.id != old.id)
        #expect(f.center.pending == [new.id])
        #expect(f.scheduler.activeReminder(matching: .phIINewCampus, departureDate: new.departureDate,
                                          referenceDate: f.now) == new)
    }

    @Test("Permission denial leaves an existing reminder intact")
    func permissionDenied() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice())
        let old = try #require(f.scheduler.activeReminder)
        f.center.denyPermission = true
        do { try await f.schedule(f.choice()); Issue.record("Permission denial ignored") }
        catch BusReminderScheduler.SchedulingError.notificationsDenied { }
        #expect(f.scheduler.activeReminder == old)
        #expect(f.center.pending == [old.id])
    }

    @Test("Choice expiring during add is cleaned up without replacing the old reminder")
    func expiresDuringAdd() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice(after: 3600))
        let old = try #require(f.scheduler.activeReminder)
        let choice = f.choice(after: 60)
        f.center.onAdd = { f.now = choice.triggerDate! }
        do { try await f.schedule(choice); Issue.record("Expired add was committed") }
        catch BusReminderScheduler.SchedulingError.unavailableChoice { }
        #expect(f.scheduler.activeReminder == old)
        #expect(f.center.pending == [old.id])
    }

    @Test("Cancellation during add removes the in-flight replacement")
    func cancelDuringAdd() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice())
        f.center.onAdd = { f.scheduler.cancelActiveReminder() }
        do { try await f.schedule(f.choice(after: 600)); Issue.record("Cancelled add was committed") }
        catch is CancellationError { }
        #expect(f.center.pending.isEmpty)
        #expect(f.scheduler.activeReminder == nil)
        #expect(f.defaults.data(forKey: "activeNextBusReminder") == nil)
    }

    @Test("An overlapping schedule cannot create a second replacement")
    func overlappingScheduleIsRejected() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        var rejected = false
        f.center.duringAdd = {
            do { try await f.schedule(f.choice(after: 600)) }
            catch BusReminderScheduler.SchedulingError.operationInProgress { rejected = true }
            catch { Issue.record("Unexpected overlap error: \(error)") }
        }
        try await f.schedule(f.choice())
        #expect(rejected)
        #expect(f.center.pending.count == 1)
    }

    @Test("Refresh retains a live reminder and removes orphaned requests")
    func refreshReconcilesRequests() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice())
        let active = try #require(f.scheduler.activeReminder)
        f.center.pending.insert("orphan")
        await f.scheduler.refresh(referenceDate: f.now)
        #expect(f.center.pending == [active.id])
        #expect(f.scheduler.activeReminder == active)
        f.center.pending.remove(active.id)
        await f.scheduler.refresh(referenceDate: f.now)
        #expect(f.scheduler.activeReminder == nil)
    }

    @Test("Refresh clears fired reminders and corrupt persisted data does not crash")
    func refreshExpiredAndCorruptState() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        try await f.schedule(f.choice())
        let active = try #require(f.scheduler.activeReminder)
        await f.scheduler.refresh(referenceDate: active.triggerDate)
        #expect(f.scheduler.activeReminder == nil)
        #expect(f.center.pending.isEmpty)
        f.defaults.set(Data("invalid".utf8), forKey: "activeNextBusReminder")
        let restored = BusReminderScheduler(center: f.center, defaults: f.defaults)
        #expect(restored.activeReminder == nil)
    }

    @Test("Refresh while scheduling cannot delete the in-flight replacement")
    func refreshDuringSchedule() async throws {
        let f = ReminderFixture(); defer { f.cleanUp() }
        f.center.duringAdd = { await f.scheduler.refresh(referenceDate: f.now) }
        try await f.schedule(f.choice())
        let active = try #require(f.scheduler.activeReminder)
        #expect(f.center.pending == [active.id])
    }
}
