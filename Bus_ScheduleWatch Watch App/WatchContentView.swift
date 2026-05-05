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
import BusScheduleCore

struct WatchContentView: View {
    @State private var primaryRoute: Location = SharedStore.readPrimaryRoute()
    @State private var dayType: DayType = .weekday
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(at: context.date)
        }
        .containerBackground(.fill.tertiary, for: .navigation)
        .onAppear {
            applyRoutePreference()
            applyEffectiveDayType()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            applyRoutePreference()
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .primaryRouteDidChange)) { _ in
            applyRoutePreference()
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

            // Top spacer — together with the bottom Spacer inside each block,
            // forms a two-spring layout that adapts to any watch size.
            // 41mm: both shrink to minLength. 49mm Ultra: both grow.
            // No font/padding tweaking needed across devices.
            Spacer(minLength: 4)

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
            HStack(spacing: 7) {
                // Semantic fonts (.headline / .subheadline) — auto-scale across
                // 41mm → 49mm Ultra and follow Dynamic Type. No hard-coded pt.
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(WidgetTheme.routeLabel(for: primaryRoute))
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                // Swap affordance — bigger circular bg + clearer icon.
                // The whole row is the hit target (contentShape below).
                Image(systemName: "arrow.left.arrow.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            // Force the entire frame to be hit-testable — without this,
            // taps on the Spacer's empty space fall through.
            .contentShape(Rectangle())
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
        let progress = waitProgress(currentSeconds: currentSeconds, departureSeconds: departureSeconds)
        let barColor = WidgetTheme.countdownColor(for: urgency, location: primaryRoute)

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

        // Hairline progress bar — fills as the next bus approaches.
        // Animated for smooth visual update on TimelineView ticks.
        progressBar(progress: progress, color: barColor)
            .padding(.top, 4)
            .padding(.bottom, 2)

        // Countdown — second focal point, baseline-aligned for tight visual.
        // Semantic fonts so it scales with watch size + Dynamic Type.
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(urgency == .critical ? "Departing in" : "Leaves in")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(CountdownFormatter.string(forSeconds: remaining))
                .font(.title3.weight(.heavy).monospacedDigit())
                .fontDesign(.rounded)
                .foregroundStyle(barColor)
        }

        // Push the chips to the bottom of the screen.
        Spacer(minLength: 6)

        if !upcoming.isEmpty {
            upcomingChips(times: upcoming)
        }
    }

    /// Fraction in [0, 1] describing how far we are between the previous
    /// departure and the next one. If there is no previous departure today
    /// (we're before the first bus), falls back to a 30-minute imminence
    /// scale so the bar still has meaning.
    private func waitProgress(currentSeconds: Int, departureSeconds: Int) -> Double {
        if let prev = Schedule.previousDepartureSeconds(
            for: primaryRoute,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ), departureSeconds > prev {
            let total = Double(departureSeconds - prev)
            let elapsed = Double(currentSeconds - prev)
            return min(1, max(0, elapsed / total))
        }
        // Fallback: imminence over a 30-minute window.
        let remaining = Double(max(0, departureSeconds - currentSeconds))
        return min(1, max(0, 1 - remaining / 1800))
    }

    @ViewBuilder
    private func progressBar(progress: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(color)
                    .frame(width: max(2, geo.size.width * CGFloat(progress)))
                    .animation(.easeOut(duration: 0.6), value: progress)
            }
        }
        .frame(height: 3)
    }

    @ViewBuilder
    private func upcomingChips(times: [String]) -> some View {
        HStack(spacing: 5) {
            Text("THEN")
                .font(.caption2.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
                .padding(.trailing, 1)

            ForEach(times, id: \.self) { time in
                Text(time)
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.10), in: Capsule())
            }

            Spacer(minLength: 0)
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
        let newRoute = WidgetTheme.opposite(of: primaryRoute)
        primaryRoute = newRoute
        SharedStore.writePrimaryRoute(newRoute)
    }

    private func applyEffectiveDayType(referenceDate: Date = Date()) {
        SharedStore.selfHealOverride(for: referenceDate)
        dayType = DayType.effective(for: referenceDate).dayType
    }

    private func applyRoutePreference() {
        primaryRoute = SharedStore.readPrimaryRoute()
    }
}

#Preview {
    WatchContentView()
}
