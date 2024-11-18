import SwiftUI

struct DayTypeToggleView: View {
    @Binding var dayType: DayType
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                dayType = .weekday
            } label: {
                Text("Weekday")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(dayType == .weekday ? Color.blue : Color.clear)
                    .foregroundColor(dayType == .weekday ? .white : .gray)
            }
            
            Button {
                dayType = .weekend
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