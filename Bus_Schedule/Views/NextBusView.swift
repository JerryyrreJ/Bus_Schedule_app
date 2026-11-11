import SwiftUI
import BusScheduleCore

struct NextBusView: View {
    let location: Location
    let dayType: DayType
    var isManualOverride: Bool = false
    var isCompact: Bool = false

    @State private var showTooltip: Bool = false

    private var accentColor: Color {
        location == .phIINewCampus ? .green : .blue
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = displayState(referenceDate: context.date)

            VStack(spacing: isCompact ? 18 : 32) {
                heroBlock(state: state)
                if !state.isReturnImmediately && !state.isNoMoreBuses {
                    countdownBlock(state: state)
                    upcomingBlock(state: state)
                }
            }
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
    }

    // MARK: - Hero

    private func heroBlock(state: DisplayState) -> some View {
        VStack(spacing: isCompact ? 4 : 6) {
            if state.isReturnImmediately {
                returnImmediatelyHero(state: state)
            } else if state.isNoMoreBuses {
                noMoreBusesHero(state: state)
            } else {
                Text(BusScheduleStrings.nextDeparture)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.4)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(state.nextDeparture)
                    .font(.system(size: isCompact ? 68 : 88, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .kerning(-2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func returnImmediatelyHero(state: DisplayState) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(BusScheduleStrings.returnImmediately)
                    .font(.system(size: isCompact ? 26 : 30, weight: .semibold, design: .rounded))
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Button {
                    showTooltip.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .popover(isPresented: $showTooltip) {
                    Text(BusScheduleStrings.returnImmediatelyHelp)
                        .font(.system(size: 14))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .frame(maxWidth: 280)
                        .presentationCompactAdaptation(.popover)
                }
            }

            Text(BusScheduleStrings.continuousShuttleShort)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let deadline = state.returnImmediatelyDeadline {
                Text(BusScheduleStrings.until(deadline))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.secondary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.top, isCompact ? 16 : 24)
    }

    private func noMoreBusesHero(state: DisplayState) -> some View {
        VStack(spacing: isCompact ? 14 : 18) {
            Text(BusScheduleStrings.noMoreBusesToday)
                .font(.system(size: isCompact ? 24 : 28, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if let tomorrowStart = state.tomorrowFirstServiceStart {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text(BusScheduleStrings.firstTomorrow)
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.6)
                            .foregroundColor(.secondary)
                        if case .returnImmediately = tomorrowStart {
                            Text("· \(BusScheduleStrings.loop)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Text(tomorrowStart.compactDisplayText)
                        .font(.system(size: isCompact ? 32 : 36, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .padding(.top, 2)
            }
        }
        .padding(.top, isCompact ? 16 : 24)
    }

    // MARK: - Countdown

    private func countdownBlock(state: DisplayState) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(BusScheduleStrings.timeLeft)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Text(state.countdownText)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(proxy.size.width, max(0, proxy.size.width * state.progressValue)))
                        .animation(.linear(duration: 0.8), value: state.progressValue)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Upcoming

    private func upcomingBlock(state: DisplayState) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
            Text(BusScheduleStrings.upcoming)
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach(Array(state.upcoming.enumerated()), id: \.offset) { index, time in
                    VStack(spacing: 2) {
                        Text(time)
                            .font(.system(size: isCompact ? 17 : 18, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(relativeLabel(for: index, state: state))
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 10 : 14)

                    if index < state.upcoming.count - 1 {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 1, height: isCompact ? 24 : 28)
                    }
                }

                if state.upcoming.isEmpty {
                    Text("—")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompact ? 10 : 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
    }

    private func relativeLabel(for index: Int, state: DisplayState) -> String {
        guard let nextSeconds = Schedule.secondsFromTimeString(state.nextDeparture),
              let thisSeconds = Schedule.secondsFromTimeString(state.upcoming[index]) else {
            return ""
        }

        let diffMinutes = max(0, (thisSeconds - nextSeconds) / 60)
        return "+\(diffMinutes)m"
    }

    // MARK: - State

    private func displayState(referenceDate: Date) -> DisplayState {
        let currentSeconds = Schedule.secondsFromMidnight(for: referenceDate)

        switch Schedule.nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
        case .returnImmediately:
            return DisplayState(
                isReturnImmediately: true,
                returnImmediatelyDeadline: Schedule.returnImmediatelyDeadline(
                    dayType: dayType,
                    currentSecondsFromMidnight: currentSeconds
                )
            )

        case .scheduled(let time, let departureSecondsFromMidnight):
            return DisplayState(
                nextDeparture: time,
                countdownText: countdownString(
                    until: departureSecondsFromMidnight,
                    from: currentSeconds
                ),
                progressValue: Schedule.waitProgressFraction(
                    for: location,
                    dayType: dayType,
                    currentSecondsFromMidnight: currentSeconds
                ),
                upcoming: Schedule.upcomingDepartures(
                    for: location,
                    dayType: dayType,
                    currentSecondsFromMidnight: currentSeconds,
                    limit: 3
                )
            )

        case .noMoreBuses:
            let nextDay = Schedule.nextServiceDay(
                after: referenceDate,
                currentDayType: dayType,
                isManualOverride: isManualOverride
            )
            return DisplayState(
                isNoMoreBuses: true,
                tomorrowFirstServiceStart: Schedule.firstServiceStart(
                    for: location,
                    dayType: nextDay.dayType
                )
            )
        }
    }

    private func countdownString(until departureSeconds: Int, from currentSeconds: Int) -> String {
        let remaining = max(0, departureSeconds - currentSeconds)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        if remaining < 3600 {
            return String(format: "%dm %02ds", minutes, seconds)
        }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

}

private struct DisplayState {
    var nextDeparture: String = ""
    var countdownText: String = ""
    var progressValue: Double = 0
    var upcoming: [String] = []
    var isReturnImmediately: Bool = false
    var returnImmediatelyDeadline: String? = nil
    var isNoMoreBuses: Bool = false
    var tomorrowFirstServiceStart: ServiceStart? = nil
}

#Preview {
    NextBusView(location: .phIINewCampus, dayType: .weekday)
        .padding()
}
