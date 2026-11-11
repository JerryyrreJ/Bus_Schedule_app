//
//  MediumWidgetView.swift
//  Bus_ScheduleWidget
//
//  Swiss Departure Board medium widget layout:
//    • Full-width route header + day-type OverrideChip above a hairline
//    • Left hero column: next departure time + countdown, loop status, or night summary
//    • Right two-row board: primary follow-up / tomorrow start + opposite route status
//

import SwiftUI
import WidgetKit
import BusScheduleCore

struct MediumWidgetView: View {
    let entry: ShuttleEntry
    var style: WidgetStyle = .card

    private var primaryState: NextDepartureState {
        entry.nextDepartureState(for: entry.primaryRoute)
    }

    private var oppositeRoute: Location {
        WidgetTheme.opposite(of: entry.primaryRoute)
    }

    private var oppositeState: NextDepartureState {
        entry.nextDepartureState(for: oppositeRoute)
    }

    private var primaryAccent: Color {
        WidgetTheme.accentColor(for: entry.primaryRoute)
    }

    private var oppositeAccent: Color {
        WidgetTheme.accentColor(for: oppositeRoute)
    }

    private var isPrimaryNoMoreBuses: Bool {
        if case .noMoreBuses = primaryState { return true }
        return false
    }

    private var isOppositeNoMoreBuses: Bool {
        if case .noMoreBuses = oppositeState { return true }
        return false
    }

    private var isOvernightEnded: Bool {
        isPrimaryNoMoreBuses && isOppositeNoMoreBuses
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

        var rightColumnWidth: CGFloat { isCompactWidth ? 118 : 134 }
        var columnSpacing: CGFloat { isCompactWidth ? 8 : 10 }
        var headerBottomPadding: CGFloat { isCompactHeight ? 5.5 : 7.5 }
        var bodyTopPadding: CGFloat { isCompactHeight ? 3 : 4 }
        var rowSpacing: CGFloat { isCompactHeight ? 5.5 : 8 }
        var barHeight: CGFloat { isCompactHeight ? 25 : 28 }
        var scheduledTimeSize: CGFloat { isCompactHeight ? 40 : 46 }
        var countdownSize: CGFloat { isCompactHeight ? 14 : 15.5 }
        var upcomingTimeSize: CGFloat { isCompactHeight ? 13.5 : 15 }
        var highlightTimeSize: CGFloat { isCompactHeight ? 14.5 : 16 }
        var secondaryFollowUpSize: CGFloat { isCompactHeight ? 11 : 11.5 }
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = Metrics(
                isCompactHeight: geo.size.height < 118,
                isCompactWidth: geo.size.width < 280
            )

            VStack(alignment: .leading, spacing: 0) {
                header(metrics)
                    .padding(.bottom, metrics.headerBottomPadding)

                Rectangle()
                    .fill(Color.primary.opacity(0.10))
                    .frame(height: 0.5)

                HStack(alignment: .center, spacing: metrics.columnSpacing) {
                    leftHero(metrics)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                    rightBoard(metrics)
                        .frame(width: metrics.rightColumnWidth, alignment: .leading)
                        .padding(.top, metrics.bodyTopPadding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // MARK: - Header

    private var headerIconColor: Color {
        if style == .minimal || isPrimaryNoMoreBuses {
            return .secondary
        }
        return primaryAccent
    }

    private func header(_ m: Metrics) -> some View {
        HStack(spacing: 5.5) {
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(headerIconColor)

            ViewThatFits(in: .horizontal) {
                Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                    .font(.system(size: m.isCompactHeight ? 12 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Text(WidgetTheme.compactRouteLabel(for: entry.primaryRoute))
                    .font(.system(size: m.isCompactHeight ? 12 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if isPrimaryLastDepartureToday {
                statusBadge(BusScheduleStrings.lastUpper)
            }

            Spacer(minLength: 4)

            OverrideChip(dayType: entry.dayType, isManualOverride: entry.isManualOverride)
                .layoutPriority(1)
        }
    }

    // MARK: - Left Hero Column

    @ViewBuilder
    private func leftHero(_ m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            switch primaryState {
            case let .scheduled(time, departureSeconds):
                let remaining = Schedule.secondsRemaining(
                    until: departureSeconds,
                    from: entry.currentSecondsFromMidnight
                )
                let urgency = WidgetUrgency.from(secondsRemaining: remaining)

                VStack(alignment: .leading, spacing: m.isCompactHeight ? 1.5 : 2.5) {
                    Text(time)
                        .font(.system(
                            size: m.scheduledTimeSize,
                            weight: WidgetTheme.bigTimeWeight(for: urgency),
                            design: .rounded
                        ))
                        .monospacedDigit()
                        .kerning(-1.5)
                        .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    WidgetCountdownLabel(
                        seconds: remaining,
                        caption: urgency == .critical ? BusScheduleStrings.departingIn : BusScheduleStrings.leavesIn,
                        fontSize: m.countdownSize,
                        color: WidgetTheme.countdownColor(for: urgency, location: entry.primaryRoute)
                    )
                }

            case .returnImmediately:
                VStack(alignment: .leading, spacing: m.isCompactHeight ? 2.5 : 3.5) {
                    Text(BusScheduleStrings.loopActive)
                        .font(.system(size: m.isCompactHeight ? 23 : 27, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(BusScheduleStrings.continuousShuttleShort)
                        .font(.system(size: m.isCompactHeight ? 11 : 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

            case .noMoreBuses:
                VStack(alignment: .leading, spacing: m.isCompactHeight ? 3 : 4) {
                    Text(BusScheduleStrings.serviceEnded)
                        .font(.system(size: m.isCompactHeight ? 17 : 19.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if let last = primaryLastToday {
                        Text(BusScheduleStrings.lastTodayWas(last))
                            .font(.system(size: m.isCompactHeight ? 10.5 : 11, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    } else {
                        Text(BusScheduleStrings.serviceResumesTomorrow)
                            .font(.system(size: m.isCompactHeight ? 10.5 : 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Right Departure Board Column

    private var primaryBarColor: Color {
        if style == .minimal {
            return Color.primary.opacity(0.20)
        }
        return isPrimaryNoMoreBuses ? primaryAccent.opacity(0.65) : primaryAccent
    }

    private var oppositeBarColor: Color {
        if style == .minimal {
            return Color.primary.opacity(0.20)
        }
        return isOppositeNoMoreBuses ? oppositeAccent.opacity(0.65) : oppositeAccent.opacity(0.88)
    }

    private func rightBoard(_ m: Metrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            primaryBoardRow(m)

            Spacer(minLength: m.rowSpacing)

            oppositeBoardRow(m)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func primaryBoardRow(_ m: Metrics) -> some View {
        boardRow(barColor: primaryBarColor, m: m) {
            switch primaryState {
            case .scheduled where !isPrimaryLastDepartureToday:
                let upcoming = entry.upcomingDepartures(for: entry.primaryRoute, limit: 2)
                boardEyebrow(BusScheduleStrings.upcoming)
                Text(upcoming.joined(separator: " · "))
                    .font(.system(size: m.upcomingTimeSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

            case .returnImmediately:
                boardEyebrow(BusScheduleStrings.loopUntil)
                if let deadline = Schedule.returnImmediatelyDeadline(
                    dayType: entry.dayType,
                    currentSecondsFromMidnight: entry.currentSecondsFromMidnight
                ) {
                    Text(deadline)
                        .font(.system(size: m.highlightTimeSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    placeholderDash(m)
                }

            case .scheduled, .noMoreBuses:
                tomorrowEyebrow(
                    title: BusScheduleStrings.firstTomorrowLower,
                    serviceStart: primaryTomorrowServiceStart
                )
                serviceStartValue(primaryTomorrowServiceStart, m: m)
            }
        }
    }

    @ViewBuilder
    private func oppositeBoardRow(_ m: Metrics) -> some View {
        boardRow(barColor: oppositeBarColor, m: m) {
            if isOvernightEnded {
                tomorrowEyebrow(
                    title: "\(WidgetTheme.compactRouteLabel(for: oppositeRoute)) · \(BusScheduleStrings.tmrwPrefix)",
                    serviceStart: oppositeTomorrowServiceStart
                )
                serviceStartValue(oppositeTomorrowServiceStart, m: m)
            } else {
                ViewThatFits(in: .horizontal) {
                    boardEyebrow(WidgetTheme.routeLabel(for: oppositeRoute))
                        .fixedSize(horizontal: true, vertical: false)
                    boardEyebrow(WidgetTheme.compactRouteLabel(for: oppositeRoute))
                }

                switch oppositeState {
                case let .scheduled(time, _):
                    let oppUpcoming = entry.upcomingDepartures(for: oppositeRoute, limit: 1)
                    if let nextFollowUp = oppUpcoming.first {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                oppositePrimaryTimeText(time, m: m)
                                Text("· \(nextFollowUp)")
                                    .font(.system(size: m.secondaryFollowUpSize, weight: .medium, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .fixedSize(horizontal: true, vertical: false)

                            oppositePrimaryTimeText(time, m: m)
                        }
                    } else {
                        oppositePrimaryTimeText(time, m: m)
                    }

                case .returnImmediately:
                    Text(BusScheduleStrings.loopActive)
                        .font(.system(size: m.isCompactHeight ? 13 : 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                case .noMoreBuses:
                    Text(BusScheduleStrings.serviceEnded)
                        .font(.system(size: m.isCompactHeight ? 12 : 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
    }

    // MARK: - Row Building Blocks

    private func boardRow<Content: View>(
        barColor: Color,
        m: Metrics,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: m.isCompactWidth ? 7 : 8) {
            Capsule()
                .fill(barColor)
                .frame(width: style == .minimal ? 1.5 : 3, height: m.barHeight)

            VStack(alignment: .leading, spacing: 1) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func boardEyebrow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func tomorrowEyebrow(title: String, serviceStart: ServiceStart?) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.secondary)
            if let serviceStart, case .returnImmediately = serviceStart {
                Text("· \(BusScheduleStrings.loop)")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.72)
    }

    @ViewBuilder
    private func serviceStartValue(_ serviceStart: ServiceStart?, m: Metrics) -> some View {
        if let serviceStart {
            Text(serviceStart.compactDisplayText)
                .font(.system(size: m.highlightTimeSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        } else {
            Text(BusScheduleStrings.unavailable)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func oppositePrimaryTimeText(_ time: String, m: Metrics) -> some View {
        Text(time)
            .font(.system(size: m.highlightTimeSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }

    private func placeholderDash(_ m: Metrics) -> some View {
        Text("—")
            .font(.system(size: m.highlightTimeSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
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
            .padding(.vertical, 2.5)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.16))
            )
            .fixedSize(horizontal: true, vertical: false)
    }
}
