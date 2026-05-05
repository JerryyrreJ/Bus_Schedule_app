//
//  ComplicationViews.swift
//  Bus_ScheduleWatchWidget
//
//  Four watchOS complication views. The system renders them in vibrant
//  white-on-blur — we use foregroundStyle(.primary)/.secondary instead of
//  raw colors so the wallpaper-tinted look comes through correctly.
//

import SwiftUI
import WidgetKit
import BusScheduleCore

// MARK: - Circular

struct WatchCircularView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )

        VStack(spacing: 1) {
            switch state {
            case let .scheduled(time, departureSeconds):
                let remaining = Schedule.secondsRemaining(
                    until: departureSeconds,
                    from: entry.currentSecondsFromMidnight
                )
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(time)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                Text(CountdownFormatter.string(forSeconds: remaining))
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()

            case .returnImmediately:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                Text("Loop")
                    .font(.system(size: 11, weight: .semibold))

            case .noMoreBuses:
                Image(systemName: "moon.fill")
                    .font(.system(size: 12, weight: .semibold))
                if let first = Schedule.firstDeparture(
                    for: entry.primaryRoute,
                    dayType: Schedule.nextDayType(after: entry.date).dayType
                ) {
                    Text(first)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
}

// MARK: - Rectangular

struct WatchRectangularView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.secondary)

            switch state {
            case let .scheduled(time, departureSeconds):
                let remaining = Schedule.secondsRemaining(
                    until: departureSeconds,
                    from: entry.currentSecondsFromMidnight
                )
                Text(time)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 4) {
                    Text("in")
                        .foregroundStyle(.secondary)
                    Text(CountdownFormatter.string(forSeconds: remaining))
                        .fontWeight(.bold)
                        .monospacedDigit()
                    if let then = Schedule.upcomingDepartures(
                        for: entry.primaryRoute,
                        dayType: entry.dayType,
                        currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
                        limit: 1
                    ).first {
                        Text("· then \(then)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            case .returnImmediately:
                Text("Return Immediately")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let deadline = Schedule.returnImmediatelyDeadline(
                    dayType: entry.dayType,
                    currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                ) {
                    Text("Until \(deadline)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

            case .noMoreBuses:
                Text("Service ended")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                if let first = Schedule.firstDeparture(
                    for: entry.primaryRoute,
                    dayType: Schedule.nextDayType(after: entry.date).dayType
                ) {
                    Text("First tomorrow \(first)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Inline

struct WatchInlineView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )
        let route = WidgetTheme.compactRouteLabel(for: entry.primaryRoute)

        switch state {
        case let .scheduled(time, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            Label(
                "\(route) · \(time) · \(CountdownFormatter.string(forSeconds: remaining))",
                systemImage: WidgetTheme.busSymbol
            )
        case .returnImmediately:
            Label("\(route) · Loop active", systemImage: "arrow.triangle.2.circlepath")
        case .noMoreBuses:
            Label("\(route) · Service ended", systemImage: "moon.fill")
        }
    }
}

// MARK: - Corner (watchOS-only)

/// Corner complication for the Infograph face. Renders the countdown along the
/// curved edge with the bus icon as the inner gauge label.
struct WatchCornerView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )

        switch state {
        case let .scheduled(time, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 14, weight: .semibold))
                .widgetLabel {
                    Text("\(time) · \(CountdownFormatter.string(forSeconds: remaining))")
                        .monospacedDigit()
                }

        case .returnImmediately:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .widgetLabel {
                    Text("Loop active")
                }

        case .noMoreBuses:
            Image(systemName: "moon.fill")
                .font(.system(size: 14, weight: .semibold))
                .widgetLabel {
                    Text("Service ended")
                }
        }
    }
}
