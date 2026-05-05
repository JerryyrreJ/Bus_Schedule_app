import SwiftUI
import BusScheduleCore

struct LocationToggleView: View {
    @Binding var location: Location

    private var accentColor: Color {
        location == .phIINewCampus ? .green : .blue
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let segmentWidth = proxy.size.width / 2
                let xOffset = location == .phIINewCampus ? 0 : segmentWidth

                Capsule()
                    .fill(accentColor)
                    .frame(width: segmentWidth - 8, height: proxy.size.height - 8)
                    .offset(x: xOffset + 4, y: 4)
                    .shadow(color: accentColor.opacity(0.35), radius: 8, x: 0, y: 2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: location)
            }

            HStack(spacing: 0) {
                segmentButton(title: "Phase II", target: .phIINewCampus)
                segmentButton(title: "Phase I", target: .phIParkingLot)
            }
        }
        .frame(height: 52)
        .background(glassBackground)
        .clipShape(Capsule())
        .sensoryFeedback(.impact(weight: .medium), trigger: location)
    }

    @ViewBuilder
    private var glassBackground: some View {
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

    private func segmentButton(title: String, target: Location) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                location = target
            }
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(location == target ? .white : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LocationToggleView(location: .constant(.phIINewCampus))
        .padding()
}
