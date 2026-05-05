import SwiftUI

struct DayTypeToggleView: View {
    @Binding var dayType: DayType
    
    // 创建震动反馈生成器
    private let feedback = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        HStack(spacing: 0) {
            dayTypeButton(title: "Weekday", type: .weekday)
            dayTypeButton(title: "Saturday", type: .saturday)
            dayTypeButton(title: "Sun/Holiday", type: .sundayOrHoliday)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }

    private func dayTypeButton(title: String, type: DayType) -> some View {
        Button {
            dayType = type
            feedback.impactOccurred()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(dayType == type ? Color.blue : Color.clear)
                .foregroundColor(dayType == type ? .white : .gray)
        }
    }
} 
