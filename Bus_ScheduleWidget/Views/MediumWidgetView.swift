//
//  MediumWidgetView.swift
//  Bus_ScheduleWidget
//
//  Dual-route medium widget (per design doc Section 3):
//    • Header with bus icon, "Campus Shuttle" label, and override chip (right)
//    • Primary card (left, ~60%): full route, big time, countdown, two upcoming
//    • Secondary stack (right, ~40%): opposite-direction next + then-after
//  Falls back to a "Service ended" layout that includes both directions when
//  the primary route has no more buses today.
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: ShuttleEntry

    private var primaryState: NextDepartureState {
        Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )
    }

    private var oppositeRoute: Location { WidgetTheme.opposite(of: entry.primaryRoute) }

    private var oppositeState: NextDepartureState {
        Schedule.nextDepartureState(
            for: oppositeRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            mainGrid
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Campus Shuttle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            OverrideChip(dayType: entry.dayType, isManualOverride: entry.isManualOverride)
        }
    }

    // MARK: Body grid

    private var mainGrid: some View {
        HStack(alignment: .top, spacing: 10) {
            primaryCard
                .frame(maxWidth: .infinity, alignment: .leading)
            secondaryStack
                .frame(width: 132)
        }
    }

    // MARK: Primary (left)

    private var primaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PRIMARY")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            primaryHeadline
                .padding(.top, 2)

            Spacer(minLength: 4)
            primaryFooter
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    @ViewBuilder
    private var primaryHeadline: some View {
        switch primaryState {
        case let .scheduled(time, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            let urgency = WidgetUrgency.from(secondsRemaining: remaining)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(time)
                    .font(.system(size: 36, weight: WidgetTheme.bigTimeWeight(for: urgency), design: .rounded))
                    .monospacedDigit()
                    .kerning(-1.0)
                    .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
                Spacer()
                Text(CountdownFormatter.string(forSeconds: remaining))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WidgetTheme.countdownColor(for: urgency, location: entry.primaryRoute))
            }

        case .returnImmediately:
            VStack(alignment: .leading, spacing: 2) {
                Text("Return Immediately")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let deadline = Schedule.returnImmediatelyDeadline(
                    dayType: entry.dayType,
                    currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                ) {
                    Text("Until \(deadline)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                        .monospacedDigit()
                }
            }

        case .noMoreBuses:
            let nextDay = Schedule.nextDayType(after: entry.date)
            VStack(alignment: .leading, spacing: 2) {
                Text("Service ended")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                if let first = Schedule.firstDeparture(for: entry.primaryRoute, dayType: nextDay.dayType) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("FIRST TOMORROW")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(1.0)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(first)
                            .font(.system(size: 26, weight: .ultraLight, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var primaryFooter: some View {
        switch primaryState {
        case .scheduled:
            let upcoming = Schedule.upcomingDepartures(
                for: entry.primaryRoute,
                dayType: entry.dayType,
                currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
                limit: 2
            )
            if !upcoming.isEmpty {
                HStack {
                    Text("Then")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(upcoming.joined(separator: " · "))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        case .returnImmediately:
            Text("Continuous pickup loop is active.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        case .noMoreBuses:
            if let last = Schedule.lastDeparture(for: entry.primaryRoute, dayType: entry.dayType) {
                Text("Last today was \(last)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Secondary (right)

    private var secondaryStack: some View {
        VStack(spacing: 6) {
            secondaryCard(
                title: WidgetTheme.routeLabel(for: oppositeRoute),
                state: oppositeState
            )
            secondaryCard(
                title: "Then",
                state: secondThenState()
            )
        }
    }

    /// Compute the second-upcoming for the opposite direction. Falls through to
    /// the same-route's third upcoming if the opposite direction has nothing.
    private func secondThenState() -> NextDepartureState {
        let oppositeUpcoming = Schedule.upcomingDepartures(
            for: oppositeRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
            limit: 2
        )
        if oppositeUpcoming.count >= 2,
           let secondsFromMidnight = Schedule.secondsFromTimeString(oppositeUpcoming[1]) {
            return .scheduled(time: oppositeUpcoming[1], departureSecondsFromMidnight: secondsFromMidnight)
        }
        // Fallback: third upcoming on the primary route
        let primaryUpcoming = Schedule.upcomingDepartures(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
            limit: 3
        )
        if primaryUpcoming.count >= 3,
           let secondsFromMidnight = Schedule.secondsFromTimeString(primaryUpcoming[2]) {
            return .scheduled(time: primaryUpcoming[2], departureSecondsFromMidnight: secondsFromMidnight)
        }
        return .noMoreBuses
    }

    private func secondaryCard(title: String, state: NextDepartureState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            switch state {
            case let .scheduled(time, departureSeconds):
                let remaining = Schedule.secondsRemaining(
                    until: departureSeconds,
                    from: entry.currentSecondsFromMidnight
                )
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(time)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Spacer(minLength: 4)
                    Text(CountdownFormatter.string(forSeconds: remaining))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            case .returnImmediately:
                Text("Loop active")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
            case .noMoreBuses:
                Text("—")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
