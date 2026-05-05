import SwiftUI

struct DayTypeToggleView: View {
    @Binding var dayType: DayType
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            if isExpanded {
                segmentedControl
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            chipButton
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
        .sensoryFeedback(.selection, trigger: dayType)
    }

    // MARK: - Collapsed chip

    private var chipButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 6) {
                Text(label(for: dayType))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(chipBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var chipBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Expanded segmented

    private var segmentedControl: some View {
        ZStack {
            GeometryReader { proxy in
                let segmentWidth = proxy.size.width / 3
                let xOffset = CGFloat(index(of: dayType)) * segmentWidth

                Capsule()
                    .fill(Color.indigo)
                    .frame(width: segmentWidth - 8, height: proxy.size.height - 8)
                    .offset(x: xOffset + 4, y: 4)
                    .shadow(color: Color.indigo.opacity(0.35), radius: 8, x: 0, y: 2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: dayType)
            }

            HStack(spacing: 0) {
                segmentButton(title: "Weekday", target: .weekday)
                segmentButton(title: "Saturday", target: .saturday)
                segmentButton(title: "Sun/Holiday", target: .sundayOrHoliday)
            }
        }
        .frame(height: 44)
        .background(segmentedBackground)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var segmentedBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: Capsule())
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        }
    }

    private func segmentButton(title: String, target: DayType) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dayType = target
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(dayType == target ? .white : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func label(for type: DayType) -> String {
        switch type {
        case .weekday: return "Weekday"
        case .saturday: return "Saturday"
        case .sundayOrHoliday: return "Sun/Holiday"
        }
    }

    private func index(of type: DayType) -> Int {
        switch type {
        case .weekday: return 0
        case .saturday: return 1
        case .sundayOrHoliday: return 2
        }
    }
}

#Preview {
    DayTypeToggleView(dayType: .constant(.weekday))
        .padding()
}
