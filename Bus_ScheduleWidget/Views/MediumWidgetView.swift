//
//  MediumWidgetView.swift
//  Bus_ScheduleWidget
//
//  Dual-route medium widget (per design doc Section 3):
//    • Header with bus icon, "Campus Shuttle" label, and override chip (right)
//    • Primary card (left, ~60%): route line, big time + countdown stacked,
//      and a small footer ("Then 17:40 · 18:10")
//    • Secondary stack (right, ~40%): opposite-direction next + then-after,
//      both cards expand equally to fill widget height
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
        VStack(alignment: .leading, spacing: 8) {
            header
            mainGrid
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    // MARK: Body grid — both columns fill the available height equally

    private var mainGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            primaryCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            secondaryStack
                .frame(width: 128, alignment: .top)
        }
    }

    // MARK: Primary card (left)

    private var primaryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            routeLine
            Spacer(minLength: 4)
            primaryHeadline
            Spacer(minLength: 4)
            primaryFooter
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private var routeLine: some View {
        HStack(spacing: 4) {
            Text("PRIMARY")
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Text("·")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.tertiary)
            Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    /// Big time stacked vertically with a small "Leaves in 12m" row beneath.
    /// Vertical layout ensures the big number never has to share width with the
    /// countdown — fixes the truncation issue from v1.
    @ViewBuilder
    private var primaryHeadline: some View {
        switch primaryState {
        case let .scheduled(time, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            let urgency = WidgetUrgency.from(secondsRemaining: remaining)

            VStack(alignment: .leading, spacing: 2) {
                Text(time)
                    .font(.system(size: 36, weight: WidgetTheme.bigTimeWeight(for: urgency), design: .rounded))
                    .monospacedDigit()
                    .kerning(-1.0)
                    .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(urgency == .critical ? "Departing in" : "Leaves in")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(CountdownFormatter.string(forSeconds: remaining))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WidgetTheme.countdownColor(for: urgency, location: entry.primaryRoute))
                }
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
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("FIRST TOMORROW")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(0.8)
                            .foregroundStyle(.secondary)
                        Text(first)
                            .font(.system(size: 24, weight: .ultraLight, design: .rounded))
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
                HStack(spacing: 4) {
                    Text("Then")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(upcoming.joined(separator: " · "))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        case .returnImmediately:
            Text("Continuous pickup loop is active.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        case .noMoreBuses:
            if let last = Schedule.lastDeparture(for: entry.primaryRoute, dayType: entry.dayType) {
                Text("Last today was \(last)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Secondary stack (right) — both cards expand equally

    private var secondaryStack: some View {
        VStack(spacing: 6) {
            secondaryCard(
                title: WidgetTheme.routeLabel(for: oppositeRoute),
                state: oppositeState
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            secondaryCard(
                title: "Then",
                state: secondThenState()
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            secondaryBody(state: state)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    @ViewBuilder
    private func secondaryBody(state: NextDepartureState) -> some View {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Text(CountdownFormatter.string(forSeconds: remaining))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
}
