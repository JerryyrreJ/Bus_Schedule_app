import SwiftUI

struct NextBusView: View {
    let location: Location
    let dayType: DayType
    
    @State private var nextDeparture: String = ""
    @State private var countdown: String = ""
    @State private var isReturnImmediately: Bool = false
    @State private var showTooltip: Bool = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 下一班发车时间
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Next Departure")
                        .font(.headline)
                    
                    Spacer()
                    
                    if isReturnImmediately {
                        HStack {
                            Text("Return Immediately")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Button {
                                showTooltip.toggle()
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.gray)
                            }
                            .popover(isPresented: $showTooltip) {
                                Text("A bus is continuously available. After dropping off passengers at Phase 1, it returns directly to Phase 2 campus for pickup.")
                                    .padding()
                            }
                        }
                    } else {
                        Text(nextDeparture)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(24)
            
            // 分割线
            if !countdown.isEmpty && !isReturnImmediately {
                Divider()
                    .padding(.horizontal, 24)
            }
            
            // 倒计时
            if !countdown.isEmpty && !isReturnImmediately {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                        Text("Time Left")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(countdown)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(uiColor: .systemGray5), lineWidth: 1)
        )
        .shadow(
            color: Color(uiColor: .systemGray4).opacity(0.5),
            radius: 5,
            x: 0,
            y: 2
        )
        .padding(.horizontal, 16)
        .onAppear {
            refreshState()
            startTimer()
        }
        .onChange(of: location) { oldValue, newValue in
            refreshState()
        }
        .onChange(of: dayType) { oldValue, newValue in
            refreshState()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startTimer() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshState()
        }
    }
    
    private func refreshState(referenceDate: Date = Date()) {
        let currentSeconds = secondsFromMidnight(for: referenceDate)

        // 重置状态
        isReturnImmediately = false
        nextDeparture = ""
        countdown = ""

        switch Schedule.nextDepartureState(
            for: location,
            dayType: dayType,
            currentSecondsFromMidnight: currentSeconds
        ) {
        case .returnImmediately:
            isReturnImmediately = true
            nextDeparture = "Return Immediately"
        case .scheduled(let time, let departureSecondsFromMidnight):
            nextDeparture = time
            countdown = countdownString(
                until: departureSecondsFromMidnight,
                from: currentSeconds
            )
        case .noMoreBuses:
            nextDeparture = "No more buses today"
        }
    }

    private func secondsFromMidnight(for date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)

        return hour * 3600 + minute * 60 + second
    }

    private func countdownString(until departureSeconds: Int, from currentSeconds: Int) -> String {
        let remainingSeconds = max(0, departureSeconds - currentSeconds)
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if remainingSeconds < 3600 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    NextBusView(location: .phIINewCampus, dayType: .weekday)
} 
