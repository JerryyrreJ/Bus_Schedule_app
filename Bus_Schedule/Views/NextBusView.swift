import SwiftUI

struct NextBusView: View {
    let location: Location
    let dayType: DayType

    @State private var nextDeparture: String = ""
    @State private var arrivalTime: String = ""
    @State private var countdownText: String = ""
    @State private var progressValue: Double = 0
    @State private var upcoming: [String] = []
    @State private var isReturnImmediately: Bool = false
    @State private var isNoMoreBuses: Bool = false
    @State private var showTooltip: Bool = false
    @State private var timer: Timer? = nil

    private var accentColor: Color {
        location == .phIINewCampus ? .green : .blue
    }

    var body: some View {
        VStack(spacing: 36) {
            heroBlock
            if !isReturnImmediately && !isNoMoreBuses {
                countdownBlock
                upcomingBlock
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            refreshState()
            startTimer()
        }
        .onChange(of: location) { _, _ in refreshState() }
        .onChange(of: dayType) { _, _ in refreshState() }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(spacing: 6) {
            Text("Next Departure")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if isReturnImmediately {
                returnImmediatelyHero
            } else if isNoMoreBuses {
                Text("No more buses today")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
            } else {
                Text(nextDeparture)
                    .font(.system(size: 88, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .kerning(-2)
                    .foregroundColor(.primary)

                if !arrivalTime.isEmpty {
                    HStack(spacing: 4) {
                        Text("Arriving")
                        Text(arrivalTime)
                            .monospacedDigit()
                            .foregroundColor(.primary.opacity(0.85))
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                }
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

    private var countdownBlock: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Time Left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(countdownText)
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
                        .frame(width: proxy.size.width * progressValue)
                        .animation(.linear(duration: 0.8), value: progressValue)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Upcoming

    private var upcomingBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach(Array(upcoming.enumerated()), id: \.offset) { index, time in
                    VStack(spacing: 2) {
                        Text(time)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                        Text(relativeLabel(for: index))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)

                    if index < upcoming.count - 1 {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 1, height: 28)
                    }
                }

                if upcoming.isEmpty {
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

    private func relativeLabel(for index: Int) -> String {
        guard let nextSeconds = secondsFromTimeString(nextDeparture),
              let thisSeconds = secondsFromTimeString(upcoming[index]) else {
            return ""
        }
        let diffMinutes = max(0, (thisSeconds - nextSeconds) / 60)
        return "+\(diffMinutes)m"
    }

    // MARK: - State refresh

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshState()
        }
    }

    private func refreshState(referenceDate: Date = Date()) {
        let currentSeconds = secondsFromMidnight(for: referenceDate)

        isReturnImmediately = false
        isNoMoreBuses = false
        nextDeparture = ""
        arrivalTime = ""
        countdownText = ""
        progressValue = 0
        upcoming = []

        switch Schedule.nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
        case .returnImmediately:
            isReturnImmediately = true

        case .scheduled(let time, let departureSecondsFromMidnight):
            nextDeparture = time
            arrivalTime = computedArrival(forDeparture: time)
            countdownText = countdownString(
                until: departureSecondsFromMidnight,
                from: currentSeconds
            )
            progressValue = computedProgress(
                until: departureSecondsFromMidnight,
                from: currentSeconds
            )
            upcoming = Schedule.upcomingDepartures(
                for: location,
                dayType: dayType,
                currentSecondsFromMidnight: currentSeconds,
                limit: 3
            )

        case .noMoreBuses:
            isNoMoreBuses = true
        }
    }

    private func computedArrival(forDeparture time: String) -> String {
        // Phase II → Phase I 是一段路程；从 schedule 模型里查对应 BusTime
        let schedule = Schedule.getCurrentSchedule(dayType)
        if let match = schedule.first(where: { busTime in
            (location == .phIINewCampus && busTime.phII == time) ||
            (location == .phIParkingLot && busTime.phI == time)
        }) {
            let other = location == .phIINewCampus ? match.phI : match.phII
            return other == "Return Immediately" ? "" : other
        }
        return ""
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

    // 进度条：以 30 分钟为参考窗口，随等待时间线性增长，封顶 1.0
    private func computedProgress(until departureSeconds: Int, from currentSeconds: Int) -> Double {
        let remaining = Double(max(0, departureSeconds - currentSeconds))
        let referenceWindow: Double = 30 * 60
        let elapsed = max(0, referenceWindow - remaining)
        return min(1.0, elapsed / referenceWindow)
    }
}

#Preview {
    NextBusView(location: .phIINewCampus, dayType: .weekday)
        .padding()
}
