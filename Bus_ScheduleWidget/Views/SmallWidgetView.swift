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

struct SmallWidgetView: View {
    let entry: ShuttleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
            upcomingFooter
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: WidgetTheme.busSymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(WidgetTheme.routeLabel(for: entry.primaryRoute))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: Body — branches on state

    @ViewBuilder
    private var content: some View {
        let state = Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )

        switch state {
        case let .scheduled(time, departureSeconds):
            scheduledBlock(time: time, departureSeconds: departureSeconds)
        case .returnImmediately:
            returnImmediatelyBlock
        case .noMoreBuses:
            noMoreBusesBlock
        }
    }

    @ViewBuilder
    private func scheduledBlock(time: String, departureSeconds: Int) -> some View {
        let remaining = Schedule.secondsRemaining(
            until: departureSeconds,
            from: entry.currentSecondsFromMidnight
        )
        let urgency = WidgetUrgency.from(secondsRemaining: remaining)
        let isCritical = urgency == .critical

        VStack(alignment: .leading, spacing: 4) {
            Text(time)
                .font(.system(
                    size: isCritical ? 50 : 56,
                    weight: WidgetTheme.bigTimeWeight(for: urgency),
                    design: .rounded
                ))
                .monospacedDigit()
                .kerning(-1.5)
                .foregroundStyle(isCritical ? Color.red : Color.primary)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            HStack {
                Text(isCritical ? "Departing in" : "Next departure")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Text(CountdownFormatter.string(forSeconds: remaining))
                    .font(.system(
                        size: isCritical ? 19 : 17,
                        weight: isCritical ? .heavy : .bold,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .foregroundStyle(WidgetTheme.countdownColor(for: urgency, location: entry.primaryRoute))
            }
        }
    }

    private var returnImmediatelyBlock: some View {
        let deadline = Schedule.returnImmediatelyDeadline(
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )
        return VStack(alignment: .leading, spacing: 4) {
            Text("Return Immediately")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.green)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            Text("Continuous pickup loop is active.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            if let deadline {
                Text("Until \(deadline)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.green)
                    .monospacedDigit()
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.green.opacity(0.16))
        )
    }

    private var noMoreBusesBlock: some View {
        let nextDay = Schedule.nextDayType(after: entry.date)
        let firstTime = Schedule.firstDeparture(for: entry.primaryRoute, dayType: nextDay.dayType)

        return VStack(alignment: .leading, spacing: 4) {
            Text("Service ended")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            if let firstTime {
                Text("FIRST TOMORROW")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(firstTime)
                    .font(.system(size: 30, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .kerning(-1.0)
                    .foregroundStyle(.primary)
            } else {
                Text("Service resumes tomorrow.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Upcoming footer (skipped for non-scheduled states)

    @ViewBuilder
    private var upcomingFooter: some View {
        let state = Schedule.nextDepartureState(
            for: entry.primaryRoute,
            dayType: entry.dayType,
            currentSecondsFromMidnight: entry.currentSecondsFromMidnight
        )
        if case .scheduled = state {
            let upcoming = Schedule.upcomingDepartures(
                for: entry.primaryRoute,
                dayType: entry.dayType,
                currentSecondsFromMidnight: entry.currentSecondsFromMidnight,
                limit: 2
            )
            if !upcoming.isEmpty {
                HStack {
                    Text("THEN")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(upcoming, id: \.self) { time in
                            Text(time)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.top, 6)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 0.5)
                }
            }
        }
    }
}
