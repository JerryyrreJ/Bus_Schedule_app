import SwiftUI

struct NextBusView: View {
    let location: Location
    let dayType: DayType
    
    @State private var nextDeparture: String = ""
    @State private var countdown: String = ""
    @State private var isReturnImmediately: Bool = false
    @State private var showTooltip: Bool = false
    @State private var timer: Timer? = nil
    @State private var minutesUntil: Int = 0
    
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
            updateNextBus()
            startTimer()
        }
        .onChange(of: location) { oldValue, newValue in
            updateNextBus()
        }
        .onChange(of: dayType) { oldValue, newValue in
            updateNextBus()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateCountdown()
        }
    }
    
    private func updateCountdown() {
        guard !nextDeparture.isEmpty && !isReturnImmediately else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTime = currentHour * 60 + currentMinute
        
        let departureComponents = nextDeparture.split(separator: ":")
        guard departureComponents.count == 2,
              let departureHour = Int(departureComponents[0]),
              let departureMinute = Int(departureComponents[1]) else {
            return
        }
        
        let departureMinutes = departureHour * 60 + departureMinute
        minutesUntil = departureMinutes - currentTime
        
        let seconds = 60 - calendar.component(.second, from: now)
        
        if minutesUntil < 60 {
            countdown = "\(minutesUntil)m \(seconds)s"
        } else {
            let hours = minutesUntil / 60
            let minutes = minutesUntil % 60
            countdown = "\(hours)h \(minutes)m"
        }
    }
    
    private func updateNextBus() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTime = hour * 60 + minute
        
        // print("Current location: \(location)")
        // print("Current time: \(hour):\(minute)")
        
        let schedule = Schedule.getCurrentSchedule(dayType)
        
        // 重置状态
        isReturnImmediately = false
        nextDeparture = ""
        countdown = ""
        
        // 检查"立即返回"状态（仅适用于一期）
        if location == .phIParkingLot {
            let currentTimeSlot = schedule.first { time in
                let phIIComponents = time.phII.split(separator: ":").map { Int($0) ?? 0 }
                let busTime = phIIComponents[0] * 60 + phIIComponents[1]
                
                if let nextTime = schedule.first(where: { $0.id == time.id + 1 }) {
                    let nextComponents = nextTime.phII.split(separator: ":").map { Int($0) ?? 0 }
                    let nextBusTime = nextComponents[0] * 60 + nextComponents[1]
                    return currentTime >= busTime && currentTime < nextBusTime
                }
                return false
            }
            
            if currentTimeSlot?.phI == "Return Immediately" {
                isReturnImmediately = true
                nextDeparture = "Return Immediately"
                print("Phase I: Return Immediately status detected")
                return
            }
        }
        
        // 查找下一班车
        if let nextBus = schedule.first(where: { time in
            let timeStr = location == .phIINewCampus ? time.phII : time.phI
            if timeStr == "Return Immediately" { return false }
            
            let components = timeStr.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else {
                return false
            }
            
            let busTime = hour * 60 + minute
            return busTime > currentTime
        }) {
            let departureTime = location == .phIINewCampus ? nextBus.phII : nextBus.phI
            nextDeparture = departureTime
            
            // 初始化倒计时
            updateCountdown()
        } else {
            nextDeparture = "No more buses today"
            countdown = ""
        }
    }
}

#Preview {
    NextBusView(location: .phIINewCampus, dayType: .weekday)
} 
