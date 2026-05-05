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
//  widget chip, the change syncs back via iCloud KV.
//

import SwiftUI
import WidgetKit
import BusScheduleCore

struct WatchContentView: View {
    /// User's preferred route on this device. Stored in App Group UserDefaults
    /// (local only, not iCloud — route preference is per-device by design).
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

        VStack(alignment: .leading, spacing: 4) {
            routeHeader
                .padding(.bottom, 2)

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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var routeHeader: some View {
        Button(action: swap) {
            HStack(spacing: 4) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(WidgetTheme.routeLabel(for: primaryRoute))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
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

        Text(time)
            .font(.system(size: 44, weight: WidgetTheme.bigTimeWeight(for: urgency), design: .rounded))
            .monospacedDigit()
            .kerning(-1.5)
            .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.55)

        HStack(spacing: 4) {
            Text(urgency == .critical ? "Departing in" : "Leaves in")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(CountdownFormatter.string(forSeconds: remaining))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(WidgetTheme.countdownColor(for: urgency, location: primaryRoute))
        }

        if !upcoming.isEmpty {
            HStack(spacing: 4) {
                Text("THEN")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(.secondary)
                Text(upcoming.joined(separator: " · "))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func returnImmediatelyBlock(currentSeconds: Int) -> some View {
        Text("Return Immediately")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.green)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

        Text("Continuous pickup loop is active.")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .lineLimit(2)

        if let deadline = Schedule.returnImmediatelyDeadline(
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
            Text("Until \(deadline)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.green)
                .monospacedDigit()
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func noMoreBusesBlock(date: Date) -> some View {
        let nextDay = Schedule.nextDayType(after: date)
        let firstTime = Schedule.firstDeparture(for: primaryRoute, dayType: nextDay.dayType)

        Text("Service ended")
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)

        if let firstTime {
            Text("FIRST TOMORROW")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.0)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(firstTime)
                .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .kerning(-1.0)
                .foregroundStyle(.primary)
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
