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
        entry.nextDepartureState(for: entry.primaryRoute)
    }

    private var oppositeRoute: Location { WidgetTheme.opposite(of: entry.primaryRoute) }

    private var oppositeState: NextDepartureState {
        entry.nextDepartureState(for: oppositeRoute)
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
        return entry.upcomingDepartures(for: entry.primaryRoute, limit: 1).isEmpty
    }

    // Tomorrow follows automatic detection because today's override expires at midnight.
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

    private struct Metrics {
        let isCompactHeight: Bool
        let isCompactWidth: Bool

        var secondaryWidth: CGFloat { isCompactWidth ? 114 : 128 }
        var minimalSecondaryWidth: CGFloat { isCompactWidth ? 112 : 126 }
        var secondarySpacing: CGFloat { isCompactHeight ? 5 : 6 }
        var minimalSecondarySpacing: CGFloat { isCompactHeight ? 4 : 6 }
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(
                isCompactHeight: geo.size.height < 118,
                isCompactWidth: geo.size.width < 280
            )
            let outerSpacing: CGFloat = metrics.isCompactHeight ? 4 : (style == .minimal ? 5 : 7)

            VStack(alignment: .leading, spacing: outerSpacing) {
                header
                content(metrics)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(BusScheduleStrings.campusShuttle)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 4)
            OverrideChip(dayType: entry.dayType, isManualOverride: entry.isManualOverride)
                .layoutPriority(1)
        }
    }

    @ViewBuilder
    private func content(_ m: Metrics) -> some View {
        switch layoutState {
        case .overnightEnded:
            overnightCard(m)
        case .default, .lastDeparture:
            mainGrid(m)
        }
    }

    @ViewBuilder
    private func mainGrid(_ m: Metrics) -> some View {
        if style == .minimal {
            minimalMainGrid(m)
        } else {
            cardMainGrid(m)
        }
    }

    private func cardMainGrid(_ m: Metrics) -> some View {
        HStack(alignment: .top, spacing: m.isCompactWidth ? 6 : 8) {
            primaryCard(m)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            secondaryStack(m)
                .frame(width: m.secondaryWidth, alignment: .top)
        }
    }

    private func minimalMainGrid(_ m: Metrics) -> some View {
        HStack(alignment: .top, spacing: m.isCompactWidth ? 6 : 8) {
            minimalPrimaryColumn(m)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            verticalHairline
                .padding(.vertical, m.isCompactHeight ? 4 : 6)

            minimalSecondaryColumn(m)
                .frame(width: m.minimalSecondaryWidth, alignment: .topLeading)
        }
    }

    private func primaryCard(_ m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            routeLine
            Spacer(minLength: 0)
            primaryHeadline(m)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, m.isCompactWidth ? 10 : 12)
        .padding(.vertical, m.isCompactHeight ? 6 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { cardBackgroundContent }
    }

    private func minimalPrimaryColumn(_ m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: m.isCompactHeight ? 1 : 2) {
            routeLine
            Spacer(minLength: 0)
            primaryHeadline(m)
            Spacer(minLength: 0)
            primaryFooter
        }
        .padding(.leading, 2)
        .padding(.trailing, 6)
    }

    private var routeLine: some View {
        HStack(spacing: 6) {
            Text(layoutState == .lastDeparture
                 ? WidgetTheme.minimalRouteLabel(for: entry.primaryRoute)
                 : WidgetTheme.routeLabel(for: entry.primaryRoute))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)

            Spacer(minLength: 0)

            if layoutState == .lastDeparture {
                statusBadge(BusScheduleStrings.lastUpper)
            }
        }
    }

    @ViewBuilder
    private func primaryHeadline(_ m: Metrics) -> some View {
        switch primaryState {
        case let .scheduled(time, departureSeconds):
            let remaining = Schedule.secondsRemaining(
                until: departureSeconds,
                from: entry.currentSecondsFromMidnight
            )
            let urgency = WidgetUrgency.from(secondsRemaining: remaining)
            let timeSize: CGFloat = style == .minimal
                ? (m.isCompactHeight ? 28 : 32)
                : (m.isCompactHeight ? 32 : 36)
            let countdownSize: CGFloat = style == .minimal
                ? (m.isCompactHeight ? 12.5 : 13.5)
                : (m.isCompactHeight ? 13 : 14)

            VStack(alignment: .leading, spacing: m.isCompactHeight ? 1 : 2) {
                Text(time)
                    .font(.system(
                        size: timeSize,
                        weight: WidgetTheme.bigTimeWeight(for: urgency),
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .kerning(-1.0)
                    .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                WidgetCountdownLabel(
                    seconds: remaining,
                    caption: urgency == .critical ? BusScheduleStrings.departingIn : BusScheduleStrings.leavesIn,
                    fontSize: countdownSize,
                    color: WidgetTheme.countdownColor(for: urgency, location: entry.primaryRoute)
                )
            }

        case .returnImmediately:
            VStack(alignment: .leading, spacing: 2) {
                Text(BusScheduleStrings.loopActive)
                    .font(.system(size: m.isCompactHeight ? 16.5 : 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let deadline = Schedule.returnImmediatelyDeadline(
                    dayType: entry.dayType,
                    currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                ) {
                    Text(BusScheduleStrings.until(deadline))
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

        case .noMoreBuses:
            VStack(alignment: .leading, spacing: 2) {
                Text(BusScheduleStrings.serviceEnded)
                    .font(.system(size: m.isCompactHeight ? 14 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let serviceStart = primaryTomorrowServiceStart {
                    VStack(alignment: .leading, spacing: 1) {
                        firstTomorrowEyebrow(for: serviceStart, fontSize: 8)
                        Text(serviceStart.compactDisplayText)
                            .font(.system(size: m.isCompactHeight ? 20 : 22, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var primaryFooter: some View {
        switch layoutState {
        case .lastDeparture:
            Text(BusScheduleStrings.lastBusToday)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

        case .default, .overnightEnded:
            switch primaryState {
            case .scheduled:
                let upcoming = entry.upcomingDepartures(for: entry.primaryRoute, limit: 2)
                if !upcoming.isEmpty {
                    let timesString = upcoming.joined(separator: " · ")
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 4) {
                            Text(BusScheduleStrings.thenLower)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text(timesString)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Text(timesString)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            case .returnImmediately:
                Text(BusScheduleStrings.continuousShuttleShort)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            case .noMoreBuses:
                if let last = primaryLastToday {
                    Text(BusScheduleStrings.lastTodayWas(last))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
    }

    @ViewBuilder
    private func overnightCard(_ m: Metrics) -> some View {
        if style == .minimal {
            minimalOvernightCard(m)
        } else {
            cardOvernightCard(m)
        }
    }

    private func cardOvernightCard(_ m: Metrics) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: m.isCompactHeight ? 4 : 6) {
                Text(BusScheduleStrings.serviceEnded)
                    .font(.system(size: m.isCompactHeight ? 16 : 17.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let last = primaryLastToday {
                    overnightDetailLine(label: BusScheduleStrings.last, value: last)
                }

                if let oppositeServiceStart = oppositeTomorrowServiceStart {
                    overnightDetailLine(label: BusScheduleStrings.other, value: oppositeServiceStart.displayText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            tomorrowStartBlock(m)
        }
        .padding(.horizontal, m.isCompactWidth ? 14 : 16)
        .padding(.vertical, m.isCompactHeight ? 6 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background { cardBackgroundContent }
    }

    private func overnightDetailLine(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private func minimalOvernightCard(_ m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(BusScheduleStrings.serviceEnded)
                    .font(.system(size: m.isCompactHeight ? 15.5 : 16.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                tomorrowStartBlock(m)
            }

            Spacer(minLength: m.isCompactHeight ? 4 : 8)

            if let footerText = overnightFooterText {
                horizontalHairline
                    .padding(.bottom, m.isCompactHeight ? 4 : 6)
                Text(footerText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, m.isCompactHeight ? 4 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func tomorrowStartBlock(_ m: Metrics) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            firstTomorrowEyebrow(for: primaryTomorrowServiceStart, fontSize: 9)
            if let serviceStart = primaryTomorrowServiceStart {
                Text(serviceStart.compactDisplayText)
                    .font(.system(size: m.isCompactHeight ? 26 : 30, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .kerning(-0.8)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(minWidth: 74, alignment: .trailing)
        .layoutPriority(1)
    }

    private func firstTomorrowEyebrow(for serviceStart: ServiceStart?, fontSize: CGFloat) -> some View {
        HStack(spacing: 3) {
            Text(BusScheduleStrings.firstTomorrow)
                .font(.system(size: fontSize, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            if let serviceStart, case .returnImmediately = serviceStart {
                Text("· \(BusScheduleStrings.loop)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private func firstTomorrowSecondaryTitle(for serviceStart: ServiceStart?) -> String {
        if let serviceStart, case .returnImmediately = serviceStart {
            return "\(BusScheduleStrings.firstTomorrowLower) · \(BusScheduleStrings.loop)"
        }
        return BusScheduleStrings.firstTomorrowLower
    }

    private var overnightFooterText: String? {
        var parts: [String] = []
        if let last = primaryLastToday {
            parts.append(BusScheduleStrings.last(last))
        }
        if let oppositeServiceStart = oppositeTomorrowServiceStart {
            parts.append(BusScheduleStrings.other(oppositeServiceStart.displayText))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func secondaryStack(_ m: Metrics) -> some View {
        VStack(spacing: m.secondarySpacing) {
            routeSecondaryCard(
                title: WidgetTheme.routeLabel(for: oppositeRoute),
                state: oppositeState,
                m: m
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            switch layoutState {
            case .lastDeparture:
                infoSecondaryCard(
                    title: firstTomorrowSecondaryTitle(for: primaryTomorrowServiceStart),
                    serviceStart: primaryTomorrowServiceStart,
                    m: m
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .default:
                genericSecondaryCard(
                    title: BusScheduleStrings.thenLower,
                    state: secondThenState(),
                    m: m
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .overnightEnded:
                EmptyView()
            }
        }
    }

    private func minimalSecondaryColumn(_ m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: m.minimalSecondarySpacing) {
            minimalSecondarySection(
                title: WidgetTheme.routeLabel(for: oppositeRoute),
                state: oppositeState,
                noMoreStyle: .serviceEnded,
                m: m
            )

            horizontalHairline
                .padding(.horizontal, 4)

            switch layoutState {
            case .lastDeparture:
                minimalInfoSection(
                    title: firstTomorrowSecondaryTitle(for: primaryTomorrowServiceStart),
                    serviceStart: primaryTomorrowServiceStart,
                    m: m
                )
            case .default:
                minimalSecondarySection(
                    title: BusScheduleStrings.thenLower,
                    state: secondThenState(),
                    noMoreStyle: .dash,
                    m: m
                )
            case .overnightEnded:
                EmptyView()
            }
        }
    }

    private func minimalInfoSection(title: String, serviceStart: ServiceStart?, m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: m.isCompactHeight ? 2 : 4) {
            minimalSecondaryTitle(title)

            if let serviceStart {
                Text(serviceStart.compactDisplayText)
                    .font(.system(size: m.isCompactHeight ? 18.5 : 20.5, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else {
                Text(BusScheduleStrings.unavailable)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private func minimalSecondarySection(
        title: String,
        state: NextDepartureState,
        noMoreStyle: SecondaryNoMoreStyle,
        m: Metrics
    ) -> some View {
        VStack(alignment: .leading, spacing: m.isCompactHeight ? 2 : 4) {
            minimalSecondaryTitle(title)
            minimalSecondaryBody(state: state, noMoreStyle: noMoreStyle, m: m)
        }
    }

    private func minimalSecondaryTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    @ViewBuilder
    private func minimalSecondaryBody(
        state: NextDepartureState,
        noMoreStyle: SecondaryNoMoreStyle,
        m: Metrics
    ) -> some View {
        switch state {
        case let .scheduled(time, _):
            // Secondary cards already name the route. Keep the departure time;
            // the primary card owns the countdown and its visual emphasis.
            Text(time)
                .font(.system(size: m.isCompactHeight ? 18.5 : 21, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

        case .returnImmediately:
            Text(BusScheduleStrings.loopActive)
                .font(.system(size: m.isCompactHeight ? 11.5 : 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

        case .noMoreBuses:
            switch noMoreStyle {
            case .dash:
                Text("—")
                    .font(.system(size: m.isCompactHeight ? 18 : 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
            case .serviceEnded:
                Text(BusScheduleStrings.serviceEnded)
                    .font(.system(size: m.isCompactHeight ? 11.5 : 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private func secondThenState() -> NextDepartureState {
        let oppositeUpcoming = entry.upcomingDepartures(for: oppositeRoute, limit: 1)
        if let nextFollowUp = oppositeUpcoming.first,
           let secondsFromMidnight = Schedule.secondsFromTimeString(nextFollowUp) {
            return .scheduled(time: nextFollowUp, departureSecondsFromMidnight: secondsFromMidnight)
        }

        let primaryUpcoming = entry.upcomingDepartures(for: entry.primaryRoute, limit: 2)
        if primaryUpcoming.count >= 2,
           let secondsFromMidnight = Schedule.secondsFromTimeString(primaryUpcoming[1]) {
            return .scheduled(time: primaryUpcoming[1], departureSecondsFromMidnight: secondsFromMidnight)
        }

        return .noMoreBuses
    }

    private func routeSecondaryCard(title: String, state: NextDepartureState, m: Metrics) -> some View {
        secondaryCard(title: title, m: m) {
            secondaryBody(state: state, noMoreStyle: .serviceEnded, m: m)
        }
    }

    private func genericSecondaryCard(title: String, state: NextDepartureState, m: Metrics) -> some View {
        secondaryCard(title: title, m: m) {
            secondaryBody(state: state, noMoreStyle: .dash, m: m)
        }
    }

    private func infoSecondaryCard(title: String, serviceStart: ServiceStart?, m: Metrics) -> some View {
        secondaryCard(title: title, m: m) {
            if let serviceStart {
                Text(serviceStart.compactDisplayText)
                    .font(.system(size: m.isCompactHeight ? 19 : 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else {
                Text(BusScheduleStrings.unavailable)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private func secondaryCard<Content: View>(
        title: String,
        m: Metrics,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            content()
        }
        .padding(.horizontal, m.isCompactWidth ? 9 : 10)
        .padding(.vertical, m.isCompactHeight ? 3.5 : 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { cardBackgroundContent }
    }

    @ViewBuilder
    private func secondaryBody(
        state: NextDepartureState,
        noMoreStyle: SecondaryNoMoreStyle,
        m: Metrics
    ) -> some View {
        switch state {
        case let .scheduled(time, _):
            // Secondary cards already name the route. Keep the departure time;
            // the primary card owns the countdown and its visual emphasis.
            Text(time)
                .font(.system(size: m.isCompactHeight ? 19 : 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

        case .returnImmediately:
            Text(BusScheduleStrings.loopActive)
                .font(.system(size: m.isCompactHeight ? 11.5 : 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

        case .noMoreBuses:
            switch noMoreStyle {
            case .dash:
                Text("—")
                    .font(.system(size: m.isCompactHeight ? 19 : 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
            case .serviceEnded:
                Text(BusScheduleStrings.serviceEnded)
                    .font(.system(size: m.isCompactHeight ? 11.5 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private func statusBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy))
            .tracking(0.7)
            .foregroundStyle(Color.orange)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .layoutPriority(2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.16))
            )
            .fixedSize(horizontal: true, vertical: false)
    }
}

