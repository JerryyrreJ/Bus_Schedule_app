import SwiftUI

struct DayTypeToggleView: View {
    @Binding var dayType: DayType
    
    // 创建震动反馈生成器
    private let feedback = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                dayType = .weekday
                feedback.impactOccurred()
            } label: {
                Text("Weekday")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(dayType == .weekday ? Color.blue : Color.clear)
                    .foregroundColor(dayType == .weekday ? .white : .gray)
            }
            
            Button {
                dayType = .weekend
                feedback.impactOccurred()
            } label: {
                Text("Weekend")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(dayType == .weekend ? Color.blue : Color.clear)
                    .foregroundColor(dayType == .weekend ? .white : .gray)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 
