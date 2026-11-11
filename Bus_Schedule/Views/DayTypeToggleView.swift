import SwiftUI
import BusScheduleCore

struct DayTypeToggleView: View {
    @Binding var dayType: DayType
    var isManualOverride: Bool = false
    var isCompact: Bool = false
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            if isExpanded {
                segmentedControl
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            chipButton
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
        .sensoryFeedback(.selection, trigger: dayType)
    }

    // MARK: - Collapsed chip

    private var chipButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 6) {
                Text("\(modePrefix) · \(label(for: dayType))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isManualOverride ? .indigo : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor((isManualOverride ? Color.indigo : Color.secondary).opacity(0.65))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(chipBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var modePrefix: String {
        isManualOverride ? BusScheduleStrings.manual : BusScheduleStrings.auto
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
                segmentButton(title: BusScheduleStrings.weekday, shortTitle: nil, target: .weekday)
                segmentButton(title: BusScheduleStrings.saturday, shortTitle: nil, target: .saturday)
                segmentButton(
                    title: BusScheduleStrings.sunHoliday,
                    shortTitle: BusScheduleStrings.holiday,
                    target: .sundayOrHoliday
                )
            }
        }
        .frame(height: isCompact ? 40 : 44)
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

    private func segmentButton(title: String, shortTitle: String?, target: DayType) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                dayType = target
            }
        } label: {
            ViewThatFits(in: .horizontal) {
                segmentText(title, selected: dayType == target)
                    .fixedSize(horizontal: true, vertical: false)

                if let shortTitle {
                    segmentText(shortTitle, selected: dayType == target)
                        .fixedSize(horizontal: true, vertical: false)
                }

                segmentText(shortTitle ?? title, selected: dayType == target)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func segmentText(_ text: String, selected: Bool) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 12.5 : 13, weight: .semibold))
            .foregroundColor(selected ? .white : .secondary)
            .lineLimit(1)
    }

    // MARK: - Helpers

    private func label(for type: DayType) -> String {
        switch type {
        case .weekday: return BusScheduleStrings.weekday
        case .saturday: return BusScheduleStrings.saturday
        case .sundayOrHoliday: return BusScheduleStrings.sunHoliday
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
