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
        switch Schedule.circularComplicationState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            at: entry.date
        ) {
        case let .scheduled(departureTime, departureDate, gaugeStartDate):
            if let gaugeStartDate {
                Gauge(value: 1) {
                    EmptyView()
                } currentValueLabel: {
                    circularCountdownLabel(
                        departureTime: departureTime,
                        departureDate: departureDate
                    )
                } minimumValueLabel: {
                    EmptyView()
                } maximumValueLabel: {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircular)
                .tint(.primary)
                .overlay {
                    ProgressView(timerInterval: gaugeStartDate...departureDate, countsDown: false)
                        .progressViewStyle(.circular)
                        .tint(.clear)
                }
            } else {
                staticRing {
                    circularCountdownLabel(
                        departureTime: departureTime,
                        departureDate: departureDate
                    )
                }
            }

        case .returnImmediately:
            Gauge(value: 1) {
                EmptyView()
            } currentValueLabel: {
                circularStatusLabel(
                    primary: "Loop",
                    secondary: Schedule.returnImmediatelyDeadline(
                        dayType: entry.dayType,
                        currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                    )
                )
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.primary)

        case let .beforeFirstDeparture(departureTime, departureDate):
            staticRing {
                circularCountdownLabel(
                    departureTime: departureTime,
                    departureDate: departureDate
                )
            }

        case .noMoreBuses:
            staticRing {
                let nextDay = Schedule.nextDayType(after: entry.date)
                circularStatusLabel(
                    primary: "Done",
                    secondary: Schedule.firstDeparture(
                        for: entry.primaryRoute,
                        dayType: nextDay.dayType
                    )
                )
            }
        }
    }

    private func circularCountdownLabel(
        departureTime: String,
        departureDate: Date
    ) -> some View {
        let remaining = max(0, Int(departureDate.timeIntervalSince(entry.date)))

        return VStack(spacing: -1) {
            circularPrimaryText(for: departureDate, remaining: remaining)
                .font(.system(size: circularPrimaryFontSize(for: remaining), weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Text(departureTime)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func circularStatusLabel(primary: String, secondary: String?) -> some View {
        VStack(spacing: -1) {
            Text(primary)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let secondary {
                Text(secondary)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private func circularPrimaryText(for departureDate: Date, remaining: Int) -> Text {
        if remaining <= 0 {
            return Text("Now")
        }

        if remaining < 3600 {
            return Text(departureDate, style: .timer)
        }

        return Text(compactCircularDurationString(for: remaining))
    }

    private func circularPrimaryFontSize(for remaining: Int) -> CGFloat {
        remaining < 3600 ? 15 : 16
    }

    private func compactCircularDurationString(for seconds: Int) -> String {
        let totalMinutes = Int(ceil(Double(max(seconds, 0)) / 60.0))

        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours)h"
        }

        return String(format: "%dh%02d", hours, minutes)
    }

    private func staticRing<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Gauge(value: 0.01) {
            EmptyView()
        } currentValueLabel: {
            content()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.secondary.opacity(0.35))
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
