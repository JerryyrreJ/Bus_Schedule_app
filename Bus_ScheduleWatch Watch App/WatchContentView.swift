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

import Combine
import SwiftUI
import BusScheduleCore

struct WatchContentView: View {
    @State private var primaryRoute: Location = SharedStore.readPrimaryRoute()
    @State private var refreshToken: Int = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 60 : 1)) { context in
            let resolved = DayType.effective(for: context.date)
            renderedContent(
                at: context.date,
                route: primaryRoute,
                resolvedDayType: resolved.dayType,
                isManualOverride: resolved.isManualOverride,
                luminanceReduced: isLuminanceReduced
            )
            .id(refreshToken)
        }
        .containerBackground(.fill.tertiary, for: .navigation)
        .onAppear {
            SharedStore.startWatchSync()
            applyRoutePreference()
            applyEffectiveDayType()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            SharedStore.startWatchSync()
            applyRoutePreference()
            applyEffectiveDayType()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            applyEffectiveDayType()
            refreshToken &+= 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .primaryRouteDidChange).receive(on: RunLoop.main)) { _ in
            applyRoutePreference()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dayTypeOverrideDidChange).receive(on: RunLoop.main)) { _ in
            applyEffectiveDayType()
            refreshToken &+= 1
        }
    }

    @ViewBuilder
    private func renderedContent(
        at date: Date,
        route: Location,
        resolvedDayType: DayType,
        isManualOverride: Bool,
        luminanceReduced: Bool
    ) -> some View {
        let currentSeconds = Schedule.secondsFromMidnight(for: date)
        let state = Schedule.nextDepartureState(
            for: route,
            dayType: resolvedDayType,
            currentSecondsFromMidnight: currentSeconds
        )

        GeometryReader { geo in
            let isCompact = geo.size.height < 165

            VStack(alignment: .leading, spacing: 0) {
                routeHeader(for: route)

                Spacer(minLength: 2)

                switch state {
                case let .scheduled(time, departureSeconds):
                    scheduledBlock(
                        route: route,
                        time: time,
                        departureSeconds: departureSeconds,
                        currentSeconds: currentSeconds,
                        dayType: resolvedDayType,
                        luminanceReduced: luminanceReduced,
                        isCompact: isCompact
                    )
                case .returnImmediately:
                    returnImmediatelyBlock(
                        currentSeconds: currentSeconds,
                        dayType: resolvedDayType,
                        isCompact: isCompact
                    )
                case .noMoreBuses:
                    noMoreBusesBlock(
                        date: date,
                        route: route,
                        resolvedDayType: resolvedDayType,
                        isManualOverride: isManualOverride,
                        isCompact: isCompact
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, isCompact ? 4 : 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func routeHeader(for route: Location) -> some View {
        Button(action: swap) {
            HStack(spacing: 6) {
                Image(systemName: WidgetTheme.busSymbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ViewThatFits(in: .horizontal) {
                    Text(WidgetTheme.routeLabel(for: route))
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Text(WidgetTheme.compactRouteLabel(for: route))
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .dynamicTypeSize(...DynamicTypeSize.large)
            // Force the entire frame to be hit-testable — without this,
            // taps on empty space fall through.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WidgetTheme.routeLabel(for: route))
    }

    @ViewBuilder
    private func scheduledBlock(
        route: Location,
        time: String,
        departureSeconds: Int,
        currentSeconds: Int,
        dayType: DayType,
        luminanceReduced: Bool,
        isCompact: Bool
    ) -> some View {
        let remaining = Schedule.secondsRemaining(until: departureSeconds, from: currentSeconds)
        let urgency = WidgetUrgency.from(secondsRemaining: remaining)
        let upcoming = Schedule.upcomingDepartures(
            for: route,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds,
            limit: 2
        )
        let progress = waitProgress(
            route: route,
            currentSeconds: currentSeconds,
            departureSeconds: departureSeconds,
            dayType: dayType
        )
        let barColor = WidgetTheme.countdownColor(for: urgency, location: route)
        let countdownText = luminanceReduced
            ? CountdownFormatter.widgetString(forSeconds: remaining)
            : CountdownFormatter.string(forSeconds: remaining)
        let fullCaption = urgency == .critical ? BusScheduleStrings.departingIn : BusScheduleStrings.leavesIn

        // Hero: big departure time — fills width and scales gracefully on 40mm watches.
        Text(time)
            .font(.system(
                size: isCompact ? 48 : 56,
                weight: WidgetTheme.bigTimeWeight(for: urgency),
                design: .rounded
            ))
            .monospacedDigit()
            .kerning(-2)
            .foregroundStyle(urgency == .critical ? Color.red : Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, isCompact ? 1 : 2)

        // Hairline progress bar — fills as the next bus approaches.
        progressBar(progress: progress, color: barColor)
            .padding(.vertical, isCompact ? 2.5 : 3.5)

        // Countdown — steps down caption before ever wrapping or truncating digits.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(fullCaption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                countdownValueLabel(countdownText, color: barColor, isCompact: isCompact)
            }
            .fixedSize(horizontal: true, vertical: false)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(BusScheduleStrings.inPrefix)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                countdownValueLabel(countdownText, color: barColor, isCompact: isCompact)
            }
            .fixedSize(horizontal: true, vertical: false)

            countdownValueLabel(countdownText, color: barColor, isCompact: isCompact)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(...DynamicTypeSize.large)
        .layoutPriority(1)

        // Push the chips to the bottom of the screen.
        Spacer(minLength: 4)

        if !upcoming.isEmpty {
            upcomingChips(times: upcoming)
                .layoutPriority(1)
        }
    }

    private func countdownValueLabel(_ text: String, color: Color, isCompact: Bool) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 17 : 18.5, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
    }

    /// Fraction in [0, 1] describing how far we are between the previous
    /// departure and the next one. If there is no previous departure today
    /// (we're before the first bus), falls back to a 30-minute imminence
    /// scale so the bar still has meaning.
    private func waitProgress(route: Location, currentSeconds: Int, departureSeconds: Int, dayType: DayType) -> Double {
        if let prev = Schedule.previousDepartureSeconds(
            for: route,
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
                    .frame(width: min(geo.size.width, max(progress > 0 ? 3 : 0, geo.size.width * CGFloat(progress))))
                    .animation(.easeOut(duration: 0.6), value: progress)
            }
        }
        .frame(height: 3)
    }

    @ViewBuilder
    private func upcomingChips(times: [String]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 5) {
                Text(BusScheduleStrings.then)
                    .font(.caption2.weight(.heavy))
                    .tracking(1.0)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                upcomingCapsules(times: times)
            }
            .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: 5) {
                upcomingCapsules(times: times)
            }
            .fixedSize(horizontal: true, vertical: false)

            Text(times.joined(separator: " · "))
                .font(.footnote.weight(.semibold).monospacedDigit())
                .fontDesign(.rounded)
                .foregroundStyle(.primary.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(...DynamicTypeSize.large)
    }

    @ViewBuilder
    private func upcomingCapsules(times: [String]) -> some View {
        ForEach(times, id: \.self) { time in
            Text(time)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary.opacity(0.85))
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.white.opacity(0.10), in: Capsule())
        }
    }

    @ViewBuilder
    private func returnImmediatelyBlock(currentSeconds: Int, dayType: DayType, isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(BusScheduleStrings.loopActive)
                .font(.system(size: isCompact ? 22 : 25, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(BusScheduleStrings.continuousShuttleShort)
                .font(.system(size: isCompact ? 12 : 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.top, isCompact ? 6 : 8)

        Spacer(minLength: 4)

        if let deadline = Schedule.returnImmediatelyDeadline(
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
            Divider()
                .opacity(0.25)
                .padding(.bottom, 4)

            HStack(spacing: 6) {
                Text(BusScheduleStrings.untilUpper)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Text(deadline)
                    .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                    .monospacedDigit()
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private func noMoreBusesBlock(
        date: Date,
        route: Location,
        resolvedDayType: DayType,
        isManualOverride: Bool,
        isCompact: Bool
    ) -> some View {
        let nextDay = Schedule.nextServiceDay(
            after: date,
            currentDayType: resolvedDayType,
            isManualOverride: isManualOverride
        )
        let serviceStart = Schedule.firstServiceStart(for: route, dayType: nextDay.dayType)

        Text(BusScheduleStrings.serviceEnded)
            .font(.system(size: isCompact ? 18 : 20, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, isCompact ? 6 : 8)

        Spacer(minLength: 4)

        if let serviceStart {
            Divider()
                .opacity(0.25)
                .padding(.bottom, 4)

            HStack(spacing: 4) {
                Text(BusScheduleStrings.firstTomorrow)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(.tertiary)
                if case .returnImmediately = serviceStart {
                    Text("· \(BusScheduleStrings.loop)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            Text(serviceStart.compactDisplayText)
                .font(.system(size: isCompact ? 34 : 38, weight: .light, design: .rounded))
                .monospacedDigit()
                .kerning(-1.2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
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
    }

    private func applyRoutePreference() {
        primaryRoute = SharedStore.readPrimaryRoute()
    }
}

#Preview {
    WatchContentView()
}
