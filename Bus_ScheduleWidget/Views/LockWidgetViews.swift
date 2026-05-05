//
//  LockWidgetViews.swift
//  Bus_ScheduleWidget
//
//  Three lock-screen accessory views:
//    • LockRectangularView — route, time, countdown, one follow-up
//    • LockCircularView    — bus icon + departure time + countdown
//    • LockInlineView      — single line, sits next to the time complication
//
//  Lock screen widgets are rendered in vibrant white-on-blur by the system —
//  so we use foreground tints (.primary / .secondary), not raw colors.
//

import SwiftUI
import WidgetKit

// MARK: - Rectangular

struct LockRectangularView: View {
    let entry: ShuttleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.secondary)

            Group {
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
                    Text(time)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 12, weight: .medium))

                case .returnImmediately:
                    Text("Return Immediately")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let deadline = Schedule.returnImmediatelyDeadline(
                        dayType: entry.dayType,
                        currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                    ) {
                        Text("Loop active until \(deadline)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                case .noMoreBuses:
                    Text("Service ended")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    if let first = Schedule.firstDeparture(
                        for: entry.primaryRoute,
                        dayType: Schedule.nextDayType(after: entry.date).dayType
                    ) {
                        Text("First tomorrow \(first)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Circular

struct LockCircularView: View {
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

// MARK: - Inline

struct LockInlineView: View {
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
