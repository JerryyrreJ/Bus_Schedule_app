//
//  SmallWidgetView.swift
//  Bus_ScheduleWidget
//
//  Renders the four small-widget states (per design doc Section 2):
//    • Default   — big time, countdown, two upcoming
//    • Urgent    — countdown ≤ 5 min: amber/red, heavier weight
//    • Return Immediately — green banner with deadline
//    • No More Buses — service ended, surfaces tomorrow's first
//

import SwiftUI
import WidgetKit
import BusScheduleCore

struct SmallWidgetView: View {
    let entry: ShuttleEntry

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 118
            VStack(alignment: .leading, spacing: 0) {
                header(isCompact: isCompact)
                Spacer(minLength: 2)
                content(isCompact: isCompact)
                Spacer(minLength: 2)
                upcomingFooter(isCompact: isCompact)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // MARK: Header

    private func header(isCompact: Bool) -> some View {
        let isLoop: Bool = {
            if case .returnImmediately = entry.nextDepartureState(for: entry.primaryRoute) {
                return true
            }
            return false
        }()

        return HStack(spacing: 5) {
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                    .font(.system(size: isCompact ? 12.5 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Text(WidgetTheme.compactRouteLabel(for: entry.primaryRoute))
                    .font(.system(size: isCompact ? 12.5 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if isLoop {
                Spacer(minLength: 4)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: isCompact ? 9.5 : 10, weight: .bold))
                    .foregroundStyle(Color.green)
                    .frame(width: isCompact ? 18 : 19, height: isCompact ? 18 : 19)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.15))
                    )
                    .padding(.vertical, -2)
            }
        }
    }

    // MARK: Body — branches on state

    @ViewBuilder
    private func content(isCompact: Bool) -> some View {
        let state = entry.nextDepartureState(for: entry.primaryRoute)

        switch state {
        case let .scheduled(time, departureSeconds):
            scheduledBlock(time: time, departureSeconds: departureSeconds, isCompact: isCompact)
        case .returnImmediately:
            returnImmediatelyBlock(isCompact: isCompact)
        case .noMoreBuses:
            noMoreBusesBlock(isCompact: isCompact)
        }
    }

    @ViewBuilder
    private func scheduledBlock(time: String, departureSeconds: Int, isCompact: Bool) -> some View {
        let remaining = Schedule.secondsRemaining(
            until: departureSeconds,
            from: entry.currentSecondsFromMidnight
        )
        let urgency = WidgetUrgency.from(secondsRemaining: remaining)
        let isCritical = urgency == .critical

        VStack(alignment: .leading, spacing: isCompact ? 1 : 2) {
            Text(time)
                .font(.system(
                    size: isCompact ? (isCritical ? 40 : 44) : (isCritical ? 46 : 50),
                    weight: WidgetTheme.bigTimeWeight(for: urgency),
                    design: .rounded
                ))
                .monospacedDigit()
                .kerning(-1.5)
                .foregroundStyle(isCritical ? Color.red : Color.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            WidgetCountdownLabel(
                seconds: remaining,
                caption: isCritical ? BusScheduleStrings.departingIn : BusScheduleStrings.leavesIn,
                fontSize: isCompact ? (isCritical ? 16 : 14.5) : (isCritical ? 18 : 16),
                color: WidgetTheme.countdownColor(for: urgency, location: entry.primaryRoute)
            )
            .layoutPriority(1)
        }
    }

    private func returnImmediatelyBlock(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 3 : 4) {
            Text(BusScheduleStrings.loopActive)
                .font(.system(size: isCompact ? 22 : 25, weight: .bold, design: .rounded))
                .foregroundStyle(Color.green)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(BusScheduleStrings.continuousShuttleShort)
                .font(.system(size: isCompact ? 11.5 : 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func noMoreBusesBlock(isCompact: Bool) -> some View {
        let nextDay = Schedule.nextServiceDay(
            after: entry.date,
            currentDayType: entry.dayType,
            isManualOverride: entry.isManualOverride
        )
        let serviceStart = Schedule.firstServiceStart(for: entry.primaryRoute, dayType: nextDay.dayType)

        return VStack(alignment: .leading, spacing: isCompact ? 3 : 4) {
            Text(BusScheduleStrings.serviceEnded)
                .font(.system(size: isCompact ? 14.5 : 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let serviceStart {
                HStack(spacing: 3) {
                    Text(BusScheduleStrings.firstTomorrow)
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                    if case .returnImmediately = serviceStart {
                        Text("· \(BusScheduleStrings.loop)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.72)

                Text(serviceStart.compactDisplayText)
                    .font(.system(size: isCompact ? 26 : 30, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .kerning(-0.8)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text(BusScheduleStrings.serviceResumesTomorrow)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: Footer (upcoming times for scheduled; loop deadline for returnImmediately)

    @ViewBuilder
    private func upcomingFooter(isCompact: Bool) -> some View {
        let state = entry.nextDepartureState(for: entry.primaryRoute)
        switch state {
        case .scheduled:
            let upcoming = entry.upcomingDepartures(for: entry.primaryRoute, limit: 2)
            if !upcoming.isEmpty {
                footerContainer(isCompact: isCompact) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            Text(BusScheduleStrings.then)
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(1.1)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            upcomingTimes(upcoming, isCompact: isCompact)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        upcomingTimes(upcoming, isCompact: isCompact)
                            .minimumScaleFactor(0.75)
                    }
                }
            }

        case .returnImmediately:
            if let deadline = Schedule.returnImmediatelyDeadline(
                dayType: entry.dayType,
                currentSecondsFromMidnight: entry.currentSecondsFromMidnight
            ) {
                footerContainer(isCompact: isCompact) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(BusScheduleStrings.untilUpper)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.0)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(deadline)
                            .font(.system(size: isCompact ? 12.5 : 13.5, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }

        case .noMoreBuses:
            EmptyView()
        }
    }

    private func footerContainer<Content: View>(
        isCompact: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, isCompact ? 4 : 5)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 0.5)
            }
    }

    private func upcomingTimes(_ times: [String], isCompact: Bool) -> some View {
        Text(times.joined(separator: " · "))
            .font(.system(size: isCompact ? 12 : 13, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
    }
}
