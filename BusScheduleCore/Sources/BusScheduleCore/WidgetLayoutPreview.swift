#if DEBUG
import Foundation

/// A shared set of typography boundaries, independent of today's timetable.
/// 10h02m and 23h59m intentionally stress future, longer service intervals.
public enum WidgetLayoutPreview {
    public enum Wait: Int, CaseIterable, Sendable {
        case now = 0, seconds = 59, oneMinute = 60, nineMinutes = 540
        case tenMinutes = 600, fiftyNineMinutes = 3540, oneHour = 3600
        case hourAndFortyFive = 6300, nineHours = 35940, tenHours = 36120
        case longest = 86340
    }

    public static func entry(_ wait: Wait, route: Location = .phIINewCampus) -> ShuttleEntry {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 6, hour: 12, minute: 6))!
        var entry = ShuttleEntry(date: date, primaryRoute: route, dayType: .weekday, isManualOverride: false)
        entry.previewCountdownSeconds = wait.rawValue
        return entry
    }
}
#endif
