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

    private var state: CircularComplicationState {
        #if DEBUG
        if let seconds = entry.previewCountdownSeconds {
            return .beforeFirstDeparture(departureTime: "22:08", departureDate: entry.date.addingTimeInterval(TimeInterval(seconds)))
        }
        #endif
        return Schedule.circularComplicationState(for: entry.primaryRoute, dayType: entry.dayType, at: entry.date)
    }

    var body: some View {
        switch state {
        case let .scheduled(_, departureDate, gaugeStartDate):
            if let gaugeStartDate {
                ProgressView(timerInterval: gaugeStartDate...departureDate, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    circularCountdownLabel(departureDate: departureDate)
                }
                .progressViewStyle(.circular)
                .tint(.primary)
            } else {
                staticRing {
                    circularCountdownLabel(departureDate: departureDate)
                }
            }

        case .returnImmediately:
            Gauge(value: 1) {
                EmptyView()
            } currentValueLabel: {
                circularStatusLabel(primary: BusScheduleStrings.loop)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.primary)

        case let .beforeFirstDeparture(_, departureDate):
            staticRing {
                circularCountdownLabel(departureDate: departureDate)
            }

        case .noMoreBuses:
            let nextDay = Schedule.nextServiceDay(
                after: entry.date,
                currentDayType: entry.dayType,
                isManualOverride: entry.isManualOverride
            )
            let serviceStart = Schedule.firstServiceStart(
                for: entry.primaryRoute,
                dayType: nextDay.dayType
            )
            staticRing {
                circularStatusLabel(primary: serviceStart?.compactDisplayText ?? BusScheduleStrings.done)
            }
        }
    }

    private func circularCountdownLabel(departureDate: Date) -> some View {
        let remaining = max(0, Int(departureDate.timeIntervalSince(entry.date)))
        let minutes = CountdownFormatter.widgetMinutes(forSeconds: remaining)
        return VStack(spacing: -1.5) {
            if minutes >= 60 && minutes % 60 != 0 {
                Text("\(minutes / 60)h")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                Text(String(format: "%02dm", minutes % 60))
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
            } else {
                Text(CountdownFormatter.widgetString(forSeconds: remaining))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(BusScheduleStrings.leavesIn) \(CountdownFormatter.widgetString(forSeconds: remaining))")
    }

    private func circularStatusLabel(primary: String) -> some View {
        Text(primary)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, 2)
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
        let state = entry.nextDepartureState(for: entry.primaryRoute)
        let isScheduled: Bool = {
            if case .scheduled = state { return true }
            return false
        }()

        VStack(alignment: .leading, spacing: isScheduled ? 1.5 : 0.5) {
            HStack(spacing: 4) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 10.5, weight: .semibold))
                Text(WidgetTheme.minimalRouteLabel(for: entry.primaryRoute))
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if case let .scheduled(time, _) = state {
                    Text(time)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .foregroundStyle(.secondary)

            headline(for: state)
                .frame(maxWidth: .infinity, alignment: .leading)
            statusDetail(for: state)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func headline(for state: NextDepartureState) -> some View {
        switch state {
        case let .scheduled(_, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            Text(CountdownFormatter.widgetString(forSeconds: remaining))
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

        case .returnImmediately:
            Text(BusScheduleStrings.loopActive)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

        case .noMoreBuses:
            Text(BusScheduleStrings.serviceEnded)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder
    private func statusDetail(for state: NextDepartureState) -> some View {
        switch state {
        case .scheduled:
            EmptyView()

        case .returnImmediately:
            if let deadline = Schedule.returnImmediatelyDeadline(
                dayType: entry.dayType,
                currentSecondsFromMidnight: entry.currentSecondsFromMidnight
            ) {
                (Text(BusScheduleStrings.untilLowerPrefix + " ")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                + Text(deadline)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

        case .noMoreBuses:
            let nextDay = Schedule.nextServiceDay(
                after: entry.date,
                currentDayType: entry.dayType,
                isManualOverride: entry.isManualOverride
            )
            if let serviceStart = Schedule.firstServiceStart(
                for: entry.primaryRoute,
                dayType: nextDay.dayType
            ) {
                (Text(BusScheduleStrings.tmrwPrefix + " ")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                + Text(serviceStart.displayText)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

// MARK: - Inline

struct WatchInlineView: View {
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

// MARK: - Corner (watchOS-only)

/// Corner complication for the Infograph face. Renders the countdown along the
/// curved edge with the bus icon as the inner gauge label.
struct WatchCornerView: View {
    let entry: ShuttleEntry

    var body: some View {
        let state = entry.nextDepartureState(for: entry.primaryRoute)

        switch state {
        case let .scheduled(_, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 14, weight: .semibold))
                .widgetLabel {
                    Text(CountdownFormatter.widgetString(forSeconds: remaining))
                        .monospacedDigit()
                }

        case .returnImmediately:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .widgetLabel {
                    Text(BusScheduleStrings.loop)
                }

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
            Image(systemName: "moon.fill")
                .font(.system(size: 14, weight: .semibold))
                .widgetLabel {
                    Text(startText)
                        .monospacedDigit()
                }
        }
    }
}
