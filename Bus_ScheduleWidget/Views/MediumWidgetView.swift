//
//  MediumWidgetView.swift
//  Bus_ScheduleWidget
//
//  Medium widget states:
//    • Default          — dual-column next + follow-up layout
//    • Last Departure   — dual-column, primary route's next bus is the last today
//    • Overnight Ended  — single-card night layout after both directions end
//

import SwiftUI
import WidgetKit
import BusScheduleCore

struct MediumWidgetView: View {
    let entry: ShuttleEntry
    var style: WidgetStyle = .card

    private enum LayoutState {
        case `default`
        case lastDeparture
        case overnightEnded
    }

    private enum SecondaryNoMoreStyle {
        case dash
        case serviceEnded
    }

    @ViewBuilder
    private var cardBackgroundContent: some View {
        if style == .card {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        }
    }

    private var verticalHairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 0.5)
    }

    private var horizontalHairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(height: 0.5)
    }

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

    private var layoutState: LayoutState {
        if isOvernightEnded {
            return .overnightEnded
        }
        if isPrimaryLastDepartureToday {
            return .lastDeparture
        }
        return .default
    }

    private var isOvernightEnded: Bool {
        if case .noMoreBuses = primaryState,
           case .noMoreBuses = oppositeState {
            return true
        }
        return false
    }

    private var isPrimaryLastDepartureToday: Bool {
        guard case .scheduled = primaryState else { return false }
        return Schedule.upcomingDepartures(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
            limit: 1
        ).isEmpty
    }

    // Manual override should keep using the currently forced day type when
    // computing "tomorrow first" in the medium widget's night states.
    private var nextServiceDayType: DayType {
        Schedule.nextServiceDay(
            after: entry.date,
            currentDayType: entry.dayType,
            isManualOverride: entry.isManualOverride
        ).dayType
    }

    private var primaryTomorrowServiceStart: ServiceStart? {
        Schedule.firstServiceStart(for: entry.primaryRoute, dayType: nextServiceDayType)
    }

    private var oppositeTomorrowServiceStart: ServiceStart? {
        Schedule.firstServiceStart(for: oppositeRoute, dayType: nextServiceDayType)
    }

    private var primaryLastToday: String? {
        Schedule.lastDeparture(for: entry.primaryRoute, dayType: entry.dayType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            content
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

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
        .padding(.top, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch layoutState {
        case .overnightEnded:
            overnightCard
        case .default, .lastDeparture:
            mainGrid
        }
    }

    private var mainGrid: some View {
        HStack(alignment: .top, spacing: style == .minimal ? 12 : 8) {
            primaryCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if style == .minimal {
                verticalHairline
                    .padding(.vertical, 18)
            }
            secondaryStack
                .frame(width: 128, alignment: .top)
        }
    }

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
        .background { cardBackgroundContent }
    }

    private var routeLine: some View {
        HStack(spacing: 6) {
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
            .layoutPriority(1)

            Spacer(minLength: 0)

            if layoutState == .lastDeparture {
                statusBadge("LAST TODAY")
            }
        }
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Service ended")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                if let serviceStart = primaryTomorrowServiceStart {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("FIRST TOMORROW")
                            .font(.system(size: 8, weight: .heavy))
                            .tracking(0.8)
                            .foregroundStyle(.secondary)
                        Text(serviceStart.displayText)
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
        switch layoutState {
        case .lastDeparture:
            Text("No more departures after this")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(2)

        case .default, .overnightEnded:
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
                if let last = primaryLastToday {
                    Text("Last today was \(last)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var overnightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text("Service ended today")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("FIRST TOMORROW")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.9)
                        .foregroundStyle(.secondary)
                    if let serviceStart = primaryTomorrowServiceStart {
                        Text(serviceStart.displayText)
                            .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                            .monospacedDigit()
                            .kerning(-0.8)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }

            Spacer(minLength: 8)

            if let footerText = overnightFooterText {
                if style == .minimal {
                    horizontalHairline
                        .padding(.bottom, 6)
                }
                Text(footerText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { cardBackgroundContent }
    }

    private var overnightFooterText: String? {
        var parts: [String] = []
        if let last = primaryLastToday {
            parts.append("Last \(last)")
        }
        if let oppositeServiceStart = oppositeTomorrowServiceStart {
            parts.append("Other \(oppositeServiceStart.displayText)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var secondaryStack: some View {
        VStack(spacing: style == .minimal ? 10 : 6) {
            routeSecondaryCard(
                title: WidgetTheme.routeLabel(for: oppositeRoute),
                state: oppositeState
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if style == .minimal && layoutState != .overnightEnded {
                horizontalHairline
                    .padding(.horizontal, 12)
            }

            switch layoutState {
            case .lastDeparture:
                infoSecondaryCard(
                    title: "Tomorrow first",
                    serviceStart: primaryTomorrowServiceStart
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .default:
                genericSecondaryCard(
                    title: "Then",
                    state: secondThenState()
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .overnightEnded:
                EmptyView()
            }
        }
    }

    private func secondThenState() -> NextDepartureState {
        let oppositeUpcoming = Schedule.upcomingDepartures(
            for: oppositeRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
            limit: 1
        )
        if let nextFollowUp = oppositeUpcoming.first,
           let secondsFromMidnight = Schedule.secondsFromTimeString(nextFollowUp) {
            return .scheduled(time: nextFollowUp, departureSecondsFromMidnight: secondsFromMidnight)
        }

        let primaryUpcoming = Schedule.upcomingDepartures(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
            limit: 2
        )
        if primaryUpcoming.count >= 2,
           let secondsFromMidnight = Schedule.secondsFromTimeString(primaryUpcoming[1]) {
            return .scheduled(time: primaryUpcoming[1], departureSecondsFromMidnight: secondsFromMidnight)
        }

        return .noMoreBuses
    }

    private func routeSecondaryCard(title: String, state: NextDepartureState) -> some View {
        secondaryCard(title: title) {
            secondaryBody(state: state, noMoreStyle: .serviceEnded)
        }
    }

    private func genericSecondaryCard(title: String, state: NextDepartureState) -> some View {
        secondaryCard(title: title) {
            secondaryBody(state: state, noMoreStyle: .dash)
        }
    }

    private func infoSecondaryCard(title: String, serviceStart: ServiceStart?) -> some View {
        secondaryCard(title: title) {
            if let serviceStart {
                Text(serviceStart.displayText)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text("Unavailable")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func secondaryCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { cardBackgroundContent }
    }

    @ViewBuilder
    private func secondaryBody(
        state: NextDepartureState,
        noMoreStyle: SecondaryNoMoreStyle
    ) -> some View {
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
            switch noMoreStyle {
            case .dash:
                Text("—")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
            case .serviceEnded:
                Text("Service ended")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
    }

    private func statusBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy))
            .tracking(0.7)
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.16))
            )
    }
}
