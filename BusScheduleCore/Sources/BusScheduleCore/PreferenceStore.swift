import Foundation

/// Persistence and conflict resolution without App Group or WidgetKit side effects.
/// SharedStore supplies the entitled defaults and UI invalidation callbacks.
struct PreferenceStore {
    let defaults: UserDefaults
    var overrideDidChange: () -> Void = {}
    var routeDidChange: () -> Void = {}

    var overrideValue: String { defaults.string(forKey: SharedStore.dayTypeOverrideKey) ?? "" }
    var overrideRevision: TimeInterval { defaults.double(forKey: SharedStore.dayTypeOverrideUpdatedAtKey) }
    var overrideSource: String {
        SharedStore.normalizedSourceDeviceID(defaults.string(forKey: SharedStore.dayTypeOverrideSourceDeviceIDKey))
    }
    var overrideExpiresAt: TimeInterval {
        if defaults.object(forKey: SharedStore.dayTypeOverrideExpiresAtKey) != nil {
            return defaults.double(forKey: SharedStore.dayTypeOverrideExpiresAtKey)
        }
        // Migration for versions that used an epoch timestamp as the revision.
        guard !overrideValue.isEmpty, overrideRevision > 0 else { return 0 }
        return SharedStore.nextStartOfDay(after: Date(timeIntervalSince1970: overrideRevision)).timeIntervalSince1970
    }

    func readOverride(for date: Date) -> DayType? {
        guard !isOverrideExpired(for: date) else { return nil }
        return DayType(rawValue: overrideValue)
    }

    func isOverrideExpired(for date: Date) -> Bool {
        overrideExpiresAt > 0 && date.timeIntervalSince1970 >= overrideExpiresAt
    }

    @discardableResult
    func applyOverride(_ value: String, revision: TimeInterval, source: String, expiresAt: TimeInterval) -> Bool {
        let oldValue = overrideValue
        let oldExpiry = overrideExpiresAt
        guard oldValue != value || overrideRevision != revision || overrideSource != source || oldExpiry != expiresAt else {
            return false
        }
        defaults.set(value, forKey: SharedStore.dayTypeOverrideKey)
        defaults.set(revision, forKey: SharedStore.dayTypeOverrideUpdatedAtKey)
        defaults.set(source, forKey: SharedStore.dayTypeOverrideSourceDeviceIDKey)
        defaults.set(expiresAt, forKey: SharedStore.dayTypeOverrideExpiresAtKey)
        // Expiry affects future timeline entries even when the raw day type is unchanged.
        guard oldValue != value || oldExpiry != expiresAt else { return false }
        overrideDidChange()
        return true
    }

    @discardableResult
    func applyIncomingOverride(_ value: String, revision: TimeInterval, source: String, expiresAt: TimeInterval) -> Bool {
        guard value.isEmpty || DayType(rawValue: value) != nil,
              revision.isFinite, revision >= 0, expiresAt.isFinite, expiresAt >= 0 else { return false }
        // Expiration affects visibility, not revision ordering. An old queued message
        // must not roll back the logical clock after the local override has expired.
        let comparison = SharedStore.compareIncoming(
            incomingRevision: revision, incomingSourceDeviceID: source,
            localRevision: overrideRevision, localSourceDeviceID: overrideSource
        )
        guard comparison > 0 || (comparison == 0 && overrideValue == value && overrideExpiresAt == expiresAt) else {
            return false
        }
        return applyOverride(value, revision: revision, source: source, expiresAt: expiresAt)
    }

    var primaryRoute: Location {
        Location(rawValue: defaults.string(forKey: SharedStore.primaryRouteKey) ?? "") ?? .phIINewCampus
    }
    var routeRevision: TimeInterval { defaults.double(forKey: SharedStore.primaryRouteUpdatedAtKey) }
    var routeSource: String {
        SharedStore.normalizedSourceDeviceID(defaults.string(forKey: SharedStore.primaryRouteSourceDeviceIDKey))
    }

    @discardableResult
    func applyRoute(_ route: Location, revision: TimeInterval, source: String) -> Bool {
        let oldRoute = primaryRoute
        defaults.set(route.rawValue, forKey: SharedStore.primaryRouteKey)
        defaults.set(revision, forKey: SharedStore.primaryRouteUpdatedAtKey)
        defaults.set(source, forKey: SharedStore.primaryRouteSourceDeviceIDKey)
        guard oldRoute != route else { return false }
        routeDidChange()
        return true
    }

    @discardableResult
    func applyIncomingRoute(_ value: String, revision: TimeInterval, source: String) -> Bool {
        guard let route = Location(rawValue: value), revision.isFinite, revision >= 0 else { return false }
        let comparison = SharedStore.compareIncoming(
            incomingRevision: revision, incomingSourceDeviceID: source,
            localRevision: routeRevision, localSourceDeviceID: routeSource
        )
        guard comparison > 0 || (comparison == 0 &&
              defaults.string(forKey: SharedStore.primaryRouteKey) == nil) else { return false }
        return applyRoute(route, revision: revision, source: source)
    }
}
