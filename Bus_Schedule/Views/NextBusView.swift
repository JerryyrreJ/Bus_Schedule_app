import SwiftUI
import BusScheduleCore

struct NextBusView: View {
    let location: Location
    let dayType: DayType

    @State private var showTooltip: Bool = false

    private var accentColor: Color {
        location == .phIINewCampus ? .green : .blue
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let state = displayState(referenceDate: context.date)

            VStack(spacing: 36) {
                heroBlock(state: state)
                if !state.isReturnImmediately && !state.isNoMoreBuses {
                    countdownBlock(state: state)
                    upcomingBlock(state: state)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Hero

    private func heroBlock(state: DisplayState) -> some View {
        VStack(spacing: 6) {
            Text("Next Departure")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if state.isReturnImmediately {
                returnImmediatelyHero
            } else if state.isNoMoreBuses {
                Text("No more buses today")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
            } else {
                Text(state.nextDeparture)
                    .font(.system(size: 88, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .kerning(-2)
                    .foregroundColor(.primary)
            }
        }
    }

    private var returnImmediatelyHero: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Return Immediately")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.green)

                Button {
                    showTooltip.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                }
                .popover(isPresented: $showTooltip) {
                    Text("A bus is continuously available. After dropping off passengers at Phase 1, it returns directly to Phase 2 campus for pickup.")
                        .padding()
                        .frame(maxWidth: 280)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Countdown

    private func countdownBlock(state: DisplayState) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Time Left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(state.countdownText)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accentColor)
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
                        .frame(width: proxy.size.width * state.progressValue)
                        .animation(.linear(duration: 0.8), value: state.progressValue)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Upcoming

    private func upcomingBlock(state: DisplayState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach(Array(state.upcoming.enumerated()), id: \.offset) { index, time in
                    VStack(spacing: 2) {
                        Text(time)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        Text(relativeLabel(for: index, state: state))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)

                    if index < state.upcoming.count - 1 {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 1, height: 28)
                    }
                }

                if state.upcoming.isEmpty {
                    Text("—")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
    }

    private func relativeLabel(for index: Int, state: DisplayState) -> String {
        guard let nextSeconds = secondsFromTimeString(state.nextDeparture),
              let thisSeconds = secondsFromTimeString(state.upcoming[index]) else {
            return ""
        }

        let diffMinutes = max(0, (thisSeconds - nextSeconds) / 60)
        return "+\(diffMinutes)m"
    }

    // MARK: - State

    private func displayState(referenceDate: Date) -> DisplayState {
        let currentSeconds = secondsFromMidnight(for: referenceDate)

        switch Schedule.nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
        case .returnImmediately:
            return DisplayState(isReturnImmediately: true)

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
            return DisplayState(isNoMoreBuses: true)
        }
    }

    private func secondsFromMidnight(for date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        return hour * 3600 + minute * 60 + second
    }

    private func secondsFromTimeString(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }
        return (hour * 60 + minute) * 60
    }

    private func countdownString(until departureSeconds: Int, from currentSeconds: Int) -> String {
        let remaining = max(0, departureSeconds - currentSeconds)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        if remaining < 3600 {
            return String(format: "%dm %02ds", minutes, seconds)
        }
        return "\(hours)h \(minutes)m"
    }

}

private struct DisplayState {
    var nextDeparture: String = ""
    var countdownText: String = ""
    var progressValue: Double = 0
    var upcoming: [String] = []
    var isReturnImmediately: Bool = false
    var isNoMoreBuses: Bool = false
}

#Preview {
    NextBusView(location: .phIINewCampus, dayType: .weekday)
        .padding()
}
