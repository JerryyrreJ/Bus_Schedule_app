import Foundation
import Testing
@testable import BusScheduleCore

@Suite("Compact widget countdowns")
struct WidgetCountdownTests {
    @Test(arguments: [
        (59, "<1m"), (60, "1m"), (61, "2m"), (300, "5m"),
        (540, "9m"), (600, "10m"), (3540, "59m"), (3599, "1h"),
        (3600, "1h"), (3601, "1h01m"), (6300, "1h45m"),
        (35940, "9h59m"), (36000, "10h"), (36120, "10h02m"),
        (86340, "23h59m"), (86399, "24h")
    ])
    func boundaries(seconds: Int, expected: String) {
        #expect(CountdownFormatter.widgetString(forSeconds: seconds) == expected)
    }

    @Test("Every second within a day stays compact and never understates the wait")
    func exhaustiveDay() {
        for seconds in 1...86400 {
            let text = CountdownFormatter.widgetString(forSeconds: seconds)
            #expect(text.count <= 6)
            #expect(!text.contains(" "))
            #expect(!text.contains(":")) // Never mistake the countdown for a clock time.
            let minutes = CountdownFormatter.widgetMinutes(forSeconds: seconds)
            #expect(minutes * 60 >= seconds)
            #expect(minutes * 60 - seconds < 60)
        }
    }

    #if DEBUG
    @Test("Boundary previews inject the intended wait without changing normal schedule queries")
    func previewFixtures() {
        for wait in WidgetLayoutPreview.Wait.allCases {
            let entry = WidgetLayoutPreview.entry(wait)
            guard case let .scheduled(_, seconds) = entry.nextDepartureState(for: entry.primaryRoute) else {
                Issue.record("Expected a scheduled layout fixture")
                continue
            }
            #expect(seconds - entry.currentSecondsFromMidnight == wait.rawValue)
        }
        let fixture = WidgetLayoutPreview.entry(.tenHours)
        let real = ShuttleEntry(date: fixture.date, primaryRoute: fixture.primaryRoute, dayType: fixture.dayType, isManualOverride: false)
        guard case let .scheduled(_, seconds) = real.nextDepartureState(for: real.primaryRoute) else {
            Issue.record("Expected the real midday departure")
            return
        }
        #expect(seconds - real.currentSecondsFromMidnight < 3600)
    }
    #endif
}
