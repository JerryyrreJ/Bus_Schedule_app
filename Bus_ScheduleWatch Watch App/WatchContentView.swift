//
//  WatchContentView.swift
//  Bus_ScheduleWatch
//
//  Single-screen watchOS view. Shows route, big departure time, countdown,
//  and the next two upcoming times. Tap the route header (anywhere across the
//  top row) to swap directions; preference persists in App Group UserDefaults
//  so the swap survives across app launches.
//
//  Day-type override is read-only on watch — to change it, use the iPhone
//  app or widget chip, then WatchConnectivity syncs the latest state over.
//

import SwiftUI
import WidgetKit
import BusScheduleCore

struct WatchContentView: View {
    /// User's preferred route on this device. Stored in App Group UserDefaults
    /// (local only — route preference is per-device by design).
    @AppStorage("primaryRoute", store: SharedStore.localDefaults)
    private var primaryRoute: Location = .phIINewCampus

    @State private var dayType: DayType = .weekday
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(at: context.date)
        }
        .containerBackground(.fill.tertiary, for: .navigation)
        .onAppear { applyEffectiveDayType() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dayTypeOverrideDidChange)) { _ in
            applyEffectiveDayType()
        }
    }

    @ViewBuilder
    private func content(at date: Date) -> some View {
        let currentSeconds = Schedule.secondsFromMidnight(for: date)
        let state = Schedule.nextDepartureState(
            for: primaryRoute,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        )

        VStack(alignment: .leading, spacing: 0) {
            routeHeader

            switch state {
            case let .scheduled(time, departureSeconds):
                scheduledBlock(
                    time: time,
                    departureSeconds: departureSeconds,
                    currentSeconds: currentSeconds
                )
            case .returnImmediately:
                returnImmediatelyBlock(currentSeconds: currentSeconds)
            case .noMoreBuses:
                noMoreBusesBlock(date: date)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var routeHeader: some View {
        Button(action: swap) {
            HStack(spacing: 5) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(WidgetTheme.routeLabel(for: primaryRoute))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func scheduledBlock(time: String, departureSeconds: Int, currentSeconds: Int) -> some View {
        let remaining = Schedule.secondsRemaining(until: departureSeconds, from: currentSeconds)
        let urgency = WidgetUrgency.from(secondsRemaining: remaining)
        let upcoming = Schedule.upcomingDepartures(
            for: primaryRoute,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds,
            limit: 2
        )

        // Hero: big departure time — fills the full width.
        Text(time)
            .font(.system(size: 64, weight: WidgetTheme.bigTimeWeight(for: urgency), design: .rounded))
            .monospacedDigit()
            .kerning(-2)
            .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)

        // Countdown — second focal point, baseline-aligned for tight visual.
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(urgency == .critical ? "Departing in" : "Leaves in")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(CountdownFormatter.string(forSeconds: remaining))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(WidgetTheme.countdownColor(for: urgency, location: primaryRoute))
        }
        .padding(.top, 2)

        // Push the THEN row to the bottom of the screen.
        Spacer(minLength: 6)

        if !upcoming.isEmpty {
            Divider()
                .opacity(0.25)
                .padding(.bottom, 5)

            HStack(spacing: 6) {
                Text("THEN")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(.tertiary)
                Text(upcoming.joined(separator: "  ·  "))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func returnImmediatelyBlock(currentSeconds: Int) -> some View {
        Text("Return\nImmediately")
            .font(.system(size: 26, weight: .semibold, design: .rounded))
            .foregroundStyle(.green)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

        Text("Continuous pickup loop is active.")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .padding(.top, 4)

        Spacer(minLength: 6)

        if let deadline = Schedule.returnImmediatelyDeadline(
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
            Divider()
                .opacity(0.25)
                .padding(.bottom, 5)

            HStack(spacing: 6) {
                Text("UNTIL")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(.tertiary)
                Text(deadline)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                    .monospacedDigit()
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func noMoreBusesBlock(date: Date) -> some View {
        let nextDay = Schedule.nextDayType(after: date)
        let firstTime = Schedule.firstDeparture(for: primaryRoute, dayType: nextDay.dayType)

        Text("Service ended")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

        Spacer(minLength: 6)

        if let firstTime {
            Divider()
                .opacity(0.25)
                .padding(.bottom, 5)

            Text("FIRST TOMORROW")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
            Text(firstTime)
                .font(.system(size: 40, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .kerning(-1.5)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func swap() {
        primaryRoute = WidgetTheme.opposite(of: primaryRoute)
    }

    private func applyEffectiveDayType(referenceDate: Date = Date()) {
        SharedStore.selfHealOverride(for: referenceDate)
        dayType = DayType.effective(for: referenceDate).dayType
    }
}

#Preview {
    WatchContentView()
}
