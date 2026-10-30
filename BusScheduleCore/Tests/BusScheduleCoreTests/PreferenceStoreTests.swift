import Foundation
import Testing
@testable import BusScheduleCore

@Suite("Preference persistence and incoming sync")
struct PreferenceStoreTests {
    private func withStore(_ body: (UserDefaults) throws -> Void) throws {
        let name = "BusSchedulePreferenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    @Test("Override is visible before expiry and absent at or after expiry")
    func expirationBoundary() throws {
        try withStore { defaults in
            let store = PreferenceStore(defaults: defaults)
            store.applyOverride("saturday", revision: 1, source: "phone", expiresAt: 1000)
            #expect(store.readOverride(for: Date(timeIntervalSince1970: 999)) == .saturday)
            #expect(store.readOverride(for: Date(timeIntervalSince1970: 1000)) == nil)
            #expect(store.readOverride(for: Date(timeIntervalSince1970: 1001)) == nil)
            #expect(store.overrideRevision == 1) // Expiration does not reset the logical clock.
        }
    }

    @Test("Expired local override still rejects older queued messages")
    func expiredOverrideRejectsStaleMessage() throws {
        try withStore { defaults in
            let store = PreferenceStore(defaults: defaults)
            store.applyOverride("saturday", revision: 10, source: "phone", expiresAt: 1)
            #expect(!store.applyIncomingOverride("weekday", revision: 9, source: "watch", expiresAt: 3000))
            #expect(store.overrideValue == "saturday")
            #expect(store.overrideRevision == 10)
            #expect(store.applyIncomingOverride("weekday", revision: 11, source: "watch", expiresAt: 3000))
            #expect(store.overrideValue == "weekday")
            #expect(store.overrideRevision == 11)
        }
    }

    @Test("Renewing the same override invalidates widgets when its expiration changes")
    func renewalInvalidatesTimeline() throws {
        try withStore { defaults in
            var notifications = 0
            let store = PreferenceStore(defaults: defaults, overrideDidChange: { notifications += 1 })
            store.applyOverride("saturday", revision: 1, source: "phone", expiresAt: 1000)
            #expect(notifications == 1)
            #expect(store.applyIncomingOverride("saturday", revision: 2, source: "watch", expiresAt: 2000))
            #expect(notifications == 2)
            #expect(store.readOverride(for: Date(timeIntervalSince1970: 1500)) == .saturday)
            #expect(!store.applyIncomingOverride("saturday", revision: 3, source: "watch", expiresAt: 2000))
            #expect(store.overrideRevision == 3)
            #expect(notifications == 2) // Revision-only changes do not invalidate UI.
        }
    }

    @Test("Duplicate messages are idempotent and equal revisions use the source tie breaker")
    func duplicateAndTieResolution() throws {
        try withStore { defaults in
            var notifications = 0
            let store = PreferenceStore(defaults: defaults, overrideDidChange: { notifications += 1 })
            store.applyOverride("saturday", revision: 2, source: "phone", expiresAt: 1000)
            #expect(!store.applyIncomingOverride("saturday", revision: 2, source: "phone", expiresAt: 1000))
            #expect(!store.applyIncomingOverride("weekday", revision: 2, source: "a", expiresAt: 1000))
            #expect(store.applyIncomingOverride("weekday", revision: 2, source: "watch", expiresAt: 1000))
            #expect(store.overrideValue == "weekday")
            #expect(store.overrideSource == "watch")
            #expect(notifications == 2)
            #expect(store.applyIncomingOverride("", revision: 3, source: "phone", expiresAt: 0))
            #expect(store.readOverride(for: Date(timeIntervalSince1970: 500)) == nil)
        }
    }

    @Test("Malformed sync payload fields cannot corrupt stored preferences")
    func invalidPayloadsAreRejected() throws {
        try withStore { defaults in
            let store = PreferenceStore(defaults: defaults)
            #expect(!store.applyIncomingOverride("invalid", revision: 100, source: "watch", expiresAt: 1000))
            #expect(!store.applyIncomingOverride("saturday", revision: .nan, source: "watch", expiresAt: 1000))
            #expect(!store.applyIncomingOverride("saturday", revision: 1, source: "watch", expiresAt: .infinity))
            #expect(!store.applyIncomingRoute("invalid", revision: 100, source: "watch"))
            #expect(!store.applyIncomingRoute("phIParkingLot", revision: .infinity, source: "watch"))
            #expect(store.overrideValue.isEmpty)
            #expect(store.primaryRoute == .phIINewCampus)
        }
    }

    @Test("Route persistence rejects old messages and notifies only on a route change")
    func routeApplicationAndPersistence() throws {
        try withStore { defaults in
            var notifications = 0
            let store = PreferenceStore(defaults: defaults, routeDidChange: { notifications += 1 })
            #expect(store.applyIncomingRoute("phIParkingLot", revision: 2, source: "watch"))
            #expect(!store.applyIncomingRoute("phIINewCampus", revision: 1, source: "phone"))
            #expect(!store.applyIncomingRoute("phIParkingLot", revision: 3, source: "phone"))
            #expect(store.routeRevision == 3)
            #expect(notifications == 1)
            #expect(PreferenceStore(defaults: defaults).primaryRoute == .phIParkingLot)
        }
    }
}
