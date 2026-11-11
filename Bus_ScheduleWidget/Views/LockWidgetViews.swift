//
//  LockWidgetViews.swift
//  Bus_ScheduleWidget
//
//  Three lock-screen accessory views:
//    • LockRectangularView — route, time, countdown
//    • LockCircularView    — bus icon + departure time + countdown
//    • LockInlineView      — single line, sits next to the time complication
//
//  Lock screen widgets are rendered in vibrant white-on-blur by the system —
//  so we use foreground tints (.primary / .secondary), not raw colors.
//

import SwiftUI
import WidgetKit
import BusScheduleCore

// MARK: - Rectangular

struct LockRectangularView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = entry.nextDepartureState(for: entry.primaryRoute)
        let isScheduled: Bool = {
            if case .scheduled = state { return true }
            return false
        }()

        VStack(alignment: .leading, spacing: isScheduled ? 0.5 : 1.5) {
            HStack(spacing: 4) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 10.5, weight: .semibold))
                Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.secondary)

            switch state {
            case let .scheduled(time, departureSeconds):
                let remaining = Schedule.secondsRemaining(
                    until: departureSeconds,
                    from: entry.currentSecondsFromMidnight
                )
                Text(time)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                WidgetCountdownLabel(
                    seconds: remaining,
                    caption: BusScheduleStrings.inPrefix,
                    fontSize: 12
                )

            case .returnImmediately:
                Text(BusScheduleStrings.returnImmediately)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let deadline = Schedule.returnImmediatelyDeadline(
                    dayType: entry.dayType,
                    currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                ) {
                    Text(BusScheduleStrings.loopActiveUntil(deadline))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

            case .noMoreBuses:
                Text(BusScheduleStrings.serviceEnded)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let serviceStart = Schedule.firstServiceStart(
                    for: entry.primaryRoute,
                    dayType: Schedule.nextServiceDay(
                        after: entry.date,
                        currentDayType: entry.dayType,
                        isManualOverride: entry.isManualOverride
                    ).dayType
                ) {
                    Text(BusScheduleStrings.firstTomorrow(serviceStart.displayText))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
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
        let state = entry.nextDepartureState(for: entry.primaryRoute)

        VStack(spacing: 0.5) {
            switch state {
            case let .scheduled(time, departureSeconds):
                let remaining = Schedule.secondsRemaining(
                    until: departureSeconds,
                    from: entry.currentSecondsFromMidnight
                )
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 8.5, weight: .semibold))
                Text(time)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(CountdownFormatter.widgetString(forSeconds: remaining))
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

            case .returnImmediately:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12.5, weight: .semibold))
                Text(BusScheduleStrings.loop)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

            case .noMoreBuses:
                Image(systemName: "moon.fill")
                    .font(.system(size: 11.5, weight: .semibold))
                if let serviceStart = Schedule.firstServiceStart(
                    for: entry.primaryRoute,
                    dayType: Schedule.nextServiceDay(
                        after: entry.date,
                        currentDayType: entry.dayType,
                        isManualOverride: entry.isManualOverride
                    ).dayType
                ) {
                    Text(serviceStart.compactDisplayText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
    }
}

// MARK: - Inline

struct LockInlineView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = entry.nextDepartureState(for: entry.primaryRoute)
        let route = WidgetTheme.minimalRouteLabel(for: entry.primaryRoute)

        switch state {
        case let .scheduled(_, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            Label(
                "\(route) · \(CountdownFormatter.widgetString(forSeconds: remaining))",
                systemImage: WidgetTheme.busSymbol
            )
        case .returnImmediately:
            Label("\(route) · \(BusScheduleStrings.loop)", systemImage: "arrow.triangle.2.circlepath")
        case .noMoreBuses:
            let nextDay = Schedule.nextServiceDay(
                after: entry.date,
                currentDayType: entry.dayType,
                isManualOverride: entry.isManualOverride
            )
            let startText = Schedule.firstServiceStart(
                for: entry.primaryRoute,
                dayType: nextDay.dayType
            )?.compactDisplayText ?? BusScheduleStrings.done
            Label("\(route) · \(startText)", systemImage: "moon.fill")
        }
    }
}
